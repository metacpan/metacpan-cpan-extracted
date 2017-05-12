package CPAN::Testers::WWW::Statistics::Excel;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.06';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Statistics::Excel - CPAN Testers Statistics Excel tool.

=head1 SYNOPSIS

  my %hash = { logfile => 'my.log' };
  my $ct = CPAN::Testers::WWW::Statistics::Excel->new(%hash);
  $ct->create( source => $source, target => $target );

=head1 DESCRIPTION

Using previously formatted data, generate Excel format files.

=cut

# -------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use File::Basename;
use File::Path;
use HTML::Entities;
use HTML::TokeParser;
use IO::File;
use Spreadsheet::WriteExcel;

# -------------------------------------
# Variables

my %format_config = (
    head    => { border => 1, pattern => 1, color => 'black',   bg_color => 'gray',     bold => 1 },
    lots    => { border => 1, pattern => 1, color => 'black',   bg_color => 'green',    align => 'right' },
    more    => { border => 1, pattern => 1, color => 'black',   bg_color => 'lime',     align => 'right' },
    some    => { border => 1, pattern => 1, color => 'black',   bg_color => 'yellow',   align => 'right' },
    none    => { border => 1, pattern => 1, color => 'black',   bg_color => 'silver',   align => 'center', valign => 'middle' },
    totals  => { border => 1, pattern => 1, color => 'white',   bg_color => 'black',    bold => 1 },
);

# -------------------------------------
# Subroutines

=head1 INTERFACE

=head2 The Constructor

=over 4

=item * new

Object constructor. Takes an optional hash, which can contain initial settings
for log file creation:

  logfile   - path to log file
  logclean  - append (0) or overwrite/create (1)

=back

=cut

sub new {
    my $class = shift;
    my %hash  = @_;

    my $self = {};
    bless $self, $class;

    $self->logfile(  $hash{logfile}  || '' );
    $self->logclean( $hash{logclean} || 0 );

    $self->_log("logfile  =" . $self->logfile  );
    $self->_log("logclean =" . $self->logclean );

    return $self;
}

=head2 Methods

=over 4

=item * create

Method to facilitate the creation of an Excel file.

Parameter values are contained within a hash to the method:

  source    - path to source HTML containing table
  target    - path to target Excel format file

In addition the following hash values can also be passed:

  title     - title for the file (Excel property)
  author    - author of the file (Excel property)
  comments  - comments string    (Excel property)

=item * logfile

Accessor for the path to the file to use for log messages. If no path is given
either via this method or through the constructor, no log messages are printed.

=item * logclean

Accessor for log creation. If a false value will append log messages,
otherwise will overwrite any existing logfile.

=back

=cut

__PACKAGE__->mk_accessors( qw( logfile logclean ) );


sub create {
    my $self = shift;
    my %hash = @_;
    my %opt;

    $self->_log("start");

    die "Source file not provided\n"               unless(   $hash{source});
    die "Target file not provided\n"               unless(   $hash{target});
    die "Source file [$hash{source}] not found\n"  unless(-f $hash{source});
    mkpath(dirname($hash{target}));

    my $workbook = Spreadsheet::WriteExcel->new( $hash{target} ); 

    $workbook->set_custom_color(23, '#999999');   # head
    $workbook->set_custom_color(17, '#00ff00');   # lots
    $workbook->set_custom_color(11, '#99ff99');   # more
    $workbook->set_custom_color(13, '#ddffdd');   # some
    $workbook->set_custom_color(22, '#dddddd');   # none

    #  Add and define a format
    my %formats;
    for my $format (keys %format_config) {
        my $class = $workbook->add_format( %{ $format_config{$format} } ); # Add a format
        $formats{$format} = $class;
    }

    my $worksheet = $workbook->add_worksheet();

    my $cell = {};
    my ($title,$table,$row,$col) = (0,0,0,0);
    my $p = HTML::TokeParser->new( $hash{source}, %opt ); 
    while(my $token = $p->get_token) {

        # if no title given, use the H2 tag.
        unless($table || $hash{title}) {
            if($token->[0] eq 'S' && $token->[1] eq 'h2') {
                $title = 1;
                $cell = {text => ''};
                next;
            }
            if($token->[0] eq 'E' && $token->[1] eq 'h2') {
                $title = 0;
                $hash{title} = decode_entities($cell->{text});
                $self->_log("TITLE: '$cell->{text}'");
                next;
            }
            if($title && $token->[0] eq 'T') {
                $cell->{text} .= "\n"   if($cell->{text});
                $cell->{text} .= $token->[1];
            }
        }

        next    unless($table || $token->[1] eq 'table');

        if($token->[0] eq 'S' && $token->[1] eq 'table') {
            $table = 1;
            next;
        }
        if($token->[0] eq 'E' && $token->[1] eq 'table') {
            $table = 0;
            last;
        }

        if($token->[0] eq 'S' && $token->[1] eq 'tr') {
            $col = 0;
            next;
        }
        if($token->[0] eq 'E' && $token->[1] eq 'tr') {
            $row++;
            next;
        }

        if($token->[0] eq 'S' && $token->[1] eq 'th') {
            $cell = { class => 'head', text => '' };
            if($token->[2]->{class}) {
                $cell = { class => $token->[2]->{class}, text => '' };
            }
            next;
        }
        if($token->[0] eq 'E' && $token->[1] eq 'th') {
            # write cell
            $self->_log("CELL: TH: [$row/$col] $cell->{class} '$cell->{text}'");
            $worksheet->write($row, $col, decode_entities($cell->{text}), $formats{$cell->{class}});
            $col++;
            next;
        }

        if($token->[0] eq 'S' && $token->[1] eq 'td') {
            $cell = { class => 'none', text => '' };
            if($token->[2]->{class}) {
                $cell = { class => $token->[2]->{class}, text => '' };
            }
            next;
        }
        if($token->[0] eq 'E' && $token->[1] eq 'td') {
            # write cell
            $self->_log("CELL: TD: [$row/$col] $cell->{class} '$cell->{text}'");
            $worksheet->write($row, $col, decode_entities($cell->{text}), $formats{$cell->{class}});
            $col++;
            next;
        }

        if($token->[0] eq 'T') {
            $cell->{text} .= "\n"   if($cell->{text});
            $cell->{text} .= $token->[1];
        }
    }

    $hash{title}    ||= 'CPAN Testers Matrix';
    $hash{author}   ||= 'CPAN Testers';
    $hash{comments} ||= 'Copyright (C) 2009 The Perl Foundation';

    $worksheet->set_landscape();    # Landscape mode
    $worksheet->set_paper(9);       # A4
    $worksheet->fit_to_pages(0, 1); # 1 page deep, many wide
    $worksheet->set_header('&L&D&C'.$hash{title}.'&R&T');
    $worksheet->set_footer('&RPage &P of &N');

    $worksheet->repeat_rows(0, 1);      # Repeat the first two rows
    $worksheet->repeat_columns(0, 1);   # Repeat the first two columns


    $workbook->set_properties(
        title    => $hash{title},
        author   => $hash{author},
        comments => $hash{comments},
    );

    $workbook->close() or die "Error closing file: $!";
    $self->_log("finish");
}

# -------------------------------------
# Private Methods

sub _log {
    my $self = shift;
    my $log = $self->logfile or return;
    mkpath(dirname($log))   unless(-f $log);

    my $mode = $self->logclean ? 'w+' : 'a+';
    $self->logclean(0);

    my @dt = localtime(time);
    my $dt = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $dt[5]+1900,$dt[4]+1,$dt[3],$dt[2],$dt[1],$dt[0];

    my $fh = IO::File->new($log,$mode) or die "Cannot write to log file [$log]: $!\n";
    print $fh "$dt ", @_, "\n";
    $fh->close;
}

q('This module is dedicated to the Birmingham Perl Mongers');

__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Statistics-Excel

=head1 SEE ALSO

L<CPAN::Testers::WWW::Statistics>,

L<http://www.cpantesters.org/>,
L<http://stats.cpantesters.org/>,
L<http://wiki.cpantesters.org/>,
L<http://blog.cpantesters.org/>

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

L<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

L<http://iheart.cpantesters.org>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
