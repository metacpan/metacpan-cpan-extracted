package Chess::FIDE;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Exporter;
use Carp;

use LWP::UserAgent;
use IO::File;
use IO::String;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Archive::Zip::MemberRead;
use Sys::MemInfo qw(freemem freeswap);

use Chess::FIDE::Player;

our @ISA = qw(Exporter);

our $VERSION = 1.22;

our $DEFAULT_FIDE_URL = 'http://ratings.fide.com/download/players_list.zip';
our @FIDE_SEARCH_KEYS = sort keys %FIDE_defaults;

our @EXPORT = qw($DEFAULT_FIDE_URL @FIDE_SEARCH_KEYS);

sub new ($;@) {

    my $class  = shift;
    my %param  = @_;

    my $fide = {
		meta    => {},
		players => [],
	};
    my $line;

    bless $fide, $class;
    if ($param{-file} || $param{-www}) {
		my $result = $fide->load(%param);
		return 0 unless $result;
    }
	else {
		warn "No source (-file or -www) given, empty object initialized" if $ENV{CHESS_FIDE_VERBOSE};
	}
    return $fide;
}

sub load ($%) {

	my $fide  = shift;
	my %param = @_;
    if ($param{-file}) {
		my $fh = IO::File->new($param{-file}, 'r');
		if (defined $fh) {
			print "Loading $param{-file}...\n" if $ENV{CHESS_FIDE_VERBOSE};
			$fide->parseFile($fh);
		}
		else {
			warn "Couldn't read file $param{-file} $!: $param{-file}\n";
			return {};
		}
    }
    elsif ($param{-www}) {
        my $ua = LWP::UserAgent->new();
        $ua->proxy(['http'], $param{-proxy}) if $param{-proxy};
		my $url = $param{-url} || $DEFAULT_FIDE_URL;
		print "Trying to get $url...\n" if $ENV{CHESS_FIDE_VERBOSE};
		my $response = $ua->get($url);
		my $webcontent;
		if ($response->is_success) {
			$webcontent = $response->content();
		}
		else {
			warn "Cannot download playerfile: Check your network connection\n";
			return 0;
		}
		print "Got " . length($webcontent) . " bytes\n" if $ENV{CHESS_FIDE_VERBOSE};
		my $expected_memsize = length($webcontent) * 150;
		if ($expected_memsize > freemem() + freeswap()) {
			warn qq{
Likely, you will not have enough memory to load the entire file.
$expected_memsize will be the expected required memory space.
In later versions, an iterator approach will be implemented.
};
		}
        my $fh = IO::String->new(\$webcontent) or die "BLAAAH\n";
        my $zip = Archive::Zip->new();
        my $status = $zip->readFromFileHandle($fh);
		unless ($status == AZ_OK) {
			warn "Problems unzipping the downloaded file";
			return 0;
		}
        my $membername;
        for $membername ($zip->memberNames()) {
            my $fh2 = Archive::Zip::MemberRead->new($zip, $membername);
			return 0 unless defined $fh2;
			$fide->parseFile($fh2);
        }
		$fh->close();
    }
}

sub convertOldHeaderNames ($) {

	my $fide = shift;

	$fide->{meta}{sgm}  = delete $fide->{meta}{game} if $fide->{meta}{game};
	$fide->{meta}{bday} = delete $fide->{meta}{born} || delete $fide->{meta}{'b-day'};
}

sub parseHeader ($$) {

	my $fide   = shift;
	my $header = shift;

	chomp $header;
	$header = lc $header;
	$header =~ s/id number/id_number/;
	$header =~ s/titlfed/tit fed/;
	$header =~ s/gamesborn/game born/;
	my $last_field;
	my $last_start;
	while($header =~ /(\S+)/gc) {
		my $field = lc $1;
		my $lf = length($field);
		if ($field =~ /^\D\D\D\d\d$/) {
			$field = 'srtng';
		}
		my $pos = pos($header);
		my $start = $pos - $lf;
		if ($start) {
			$fide->{meta}{$last_field} = [ $last_start, $start - $last_start ];
		}
		$last_field = $field;
		$last_start = $start;
	}
	$fide->{meta}{$last_field} = [ $last_start, length($header) - $last_start ];
	$fide->{meta}{id} = delete $fide->{meta}{id_number};
	$fide->convertOldHeaderNames();
}

sub parseName ($$) {

	my $fide = shift;
	my $info = shift;
	return unless $info->{name};
	$info->{fidename} = $info->{name};
	$info->{name} =~ s/^\W+//;
	$info->{name} =~ s/\, Dr\.//;
	if ($info->{name} =~ /^(\S.*)\s*\,\s*(\S.*)/) {
		$info->{givenname} = $2;
		$info->{surname}   = $1;
		$info->{name} = "$info->{givenname} $info->{surname}";
	}
	elsif ($info->{name} =~ /^(\S.*\S)\s+(\S+)$/) {
		$info->{givenname} = $1;
		$info->{surname} = $2;
		$info->{name} = "$info->{givenname} $info->{surname}";
	}
	else {
		warn "Strange name $info->{name}, assuming both given and sur" if $ENV{CHESS_FIDE_VERBOSE};
		$info->{givenname} = $info->{surname} = $info->{name};
	}
}

sub parseLine ($$) {

    my $fide = shift;
    my $line = shift;

	chomp $line;
	my %info = ();
	my $orig_line = $line;
	for my $field (keys %{$fide->{meta}}) {
		$line = $orig_line;
		if (length($line) <= $fide->{meta}{$field}[0]-1) {
			$info{$field} = '';
			next;
		}
		my $value = $fide->{meta}{$field}[0] ?
			substr($line, $fide->{meta}{$field}[0]-1, $fide->{meta}{$field}[1]) :
			substr($line, $fide->{meta}{$field}[0], $fide->{meta}{$field}[1]-1);
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;
		$value =~ s/\s+/ /g;
		$info{$field} = $value;
	}
	$fide->parseName(\%info);
	return %info;
}

sub parseFile ($$) {

	my $fide = shift;
	my $fh   = shift;

	my $line;
	my $l = 0;
	while (defined($line = $fh->getline())) {
		$l++;
		if ($line =~ /^id/i) {
			$fide->parseHeader($line);
		}
		elsif ($line =~ /Mr., Jonathan Rose/) {
			# bogus entry in the rating list
			next;
		}
		elsif ($line =~ /^\s*\d/) {
			my %info = $fide->parseLine($line);
			if ($info{name} &&$info{name} =~ /\S/) {
				my $player = Chess::FIDE::Player->new(%info);
				push(@{$fide->{players}}, $player) if $player;
			}
		}
		else {
			warn "Line $l: $line - format not recognized, ignoring" if $ENV{CHESS_FIDE_VERBOSE};
		}
	}
	$fh->close();
}

sub fideSearch ($$;$) {

    my $fide     = shift;
    my $criteria = shift;
	my $players  = shift || $fide->{players};

	my $found = 0;
    for my $field (keys %FIDE_defaults) {
		if ($criteria =~ /^$field /i) {
			$criteria =~ s/^($field)/'$_->{'.lc($field).'}'/gei;
			$found = 1;
			last;
		}
    }
	die "Invalid criteria $criteria supplied" unless $found;
    my @found_players = grep {
		eval $criteria
	} @{$players};
	@found_players;
}

sub dumpHeader ($) {

	my $fide = shift;

	my $header = '';
	for my $field (sort { $fide->{meta}{$a}[0] <=> $fide->{meta}{$b}[0]}  keys %{$fide->{meta}}) {
		$header .= $field . (' ' x ($fide->{meta}{$field}->[1] - length($field)));
	}
	$header .= "\n";
	$header;
}

sub dumpPlayer ($$) {

	my $fide   = shift;
	my $player = shift;

	my $dump = '';
	for my $field (sort { $fide->{meta}{$a}[0] <=> $fide->{meta}{$b}[0]}  keys %{$fide->{meta}}) {
		$dump .= ($player->$field || '') . (' ' x ($fide->{meta}{$field}->[1] - length($player->$field || '')));
	}
	$dump .= "\n";
	$dump;
}
1;

__END__

=head1 NAME

Chess::FIDE - Perl extension for FIDE Rating List

=head1 SYNOPSIS

  use Chess::FIDE;
  my $fide = Chess::FIDE->new(-file=>'filename');
  my @results = $fide->fideSearch("surname eq 'Kasparov'");
  $fide->dumpPlayer($results[0]);

=head1 DESCRIPTION

Chess::FIDE - Perl extension for FIDE Rating List. FIDE is the International Chess Federation that releases a list of its rated members every month. The list contains about five hundred thousand entries. This module is designed to parse its contents and to search across it using perl expressions. A sample from an up-to-date FIDE list is provided in t/data/test-list-2.txt, while the older list sample is still available in t/data/test-list.txt

=head2 METHODS

The following methods are available:

=over

=item new /Constructor/

 $fide = Chess::FIDE->new(-file => 'localfile');
 $fide = Chess::FIDE->new(-www => 1, [ -proxy=>proxyaddress, -url => URL ]);

There are two types of constructors - one takes a local file and another one retrieves the up-to-date zip file from the FIDE site, unzips it on the fly and parses the output immediately. In case of the second constructor no files are created. Also usage of an optional proxy is possible in the second case. Also a specific URL may be specified to retrieve the file.

Each player entry in the file is scanned against a regexp and then there is a post-parsing as well which is implemented in function parseLine. The entry is then stored in an object defined by the module Chess::FIDE::Player (see its documentation). The whole list of players is stored in the players field of the Chess::FIDE object.

=item fideSearch

 @result = $fide->fideSearch("perl conditional", [ @arrayref ]);

 Example:
 @result = $fide->fideSearch("surname eq 'Kasparov'");

Searches the fide object for entries satisfying the conditional specified as the argument. The conditional operator MUST be a PERL operator. The first operand must be a valid field of the FIDE rating list. The second operand must be a value within single quotes because the conditional is 'eval'ed against each entry. Any conditional operand including a regexp match that may be eval-ed is valid. For the fields to use in conditionals see Chess::FIDE::Player documentation. Only single condition is supported at this stage. Optionally, an list of Chess::FIDE::Player objects may be supplied to search against, for example you can feed the results of the previous query.

=item dumpHeader

 print $fide->dumpHeader();

Dumps a ready to use header for a list of players to display.

=item dumpPlayer

  my @results = $fide->fideSearch("surname eq 'Kasparov'");
  $fide->dumpPlayer($results[0]);

Dumps a player object in the format almost identical to the one it was read from and ready to be re-read if necessary.

=back

=head2 AUXILIARY METHODS

=over

=item load

Load the empty FIDE object with the content specified either in -www or -file switch.

=item convertOldHeaderNames

Converts names from the headers of old FIDE files to the new ones, where required.

=item parseHeader

Parse the header of the FIDE file and assign string positions of the detected fields.

=item parseName

Parse additionally the name of the player and deduct surname and given name from it.

=item parseLine

Parse a line from the file of FIDE ratings.

=item parseFile

Parse the file of FIDE ratings.

=back

=head1 CAVEATS

The only unique entry is the id field. There are, for example, two
"Sokolov, Andrei" entries, so a search by name might be ambiguous.

Please note that the files on FIDE website are available only for the year 2001 and later.

=head1 SEE ALSO

Chess::FIDE::Player
http://www.fide.com/
Archive::Zip
LWP::UserAgent

=head1 AUTHOR

Roman M. Parparov, E<lt>romm@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2015 by Roman M. Parparov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Fide Rating List is Copyright (C) by the International Chess Federation
http://www.fide.com

=cut
