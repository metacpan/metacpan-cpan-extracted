package App::watchdiff;

##
## watchdiff: watch difference
##
## Copyright 2014- Kazumasa Utashiro
##
## Original version on Feb 15 2014
##

use v5.14;
use warnings;

use open ":std" => ":encoding(utf8)";
use Fcntl;
use Pod::Usage;
use Data::Dumper;

use List::Util qw(pairmap);

use App::sdif;
my $version = $App::sdif::VERSION;

use Getopt::EX::Hashed 'has'; {

    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);

    has help     => ' h      ' ;
    has version  => ' v      ' ;
    has debug    => ' d      ' ;
    has unit     => '    =s  ' , default => '' ;
    has diff     => '    =s  ' ;
    has exec     => ' e  =s@ ' , default => [] ;
    has refresh  => ' r  :1  ' , default => 1 ;
    has interval => ' i  =i  ' , default => 2 ;
    has count    => ' c  =i  ' , default => 1000 ;
    has clear    => '    !   ' , default => 1 ;
    has silent   => ' s  !   ' , default => 0 ;
    has mark     => ' M  !   ' , default => 0 ;
    has old      => ' O  !   ' , default => 0 ;
    has date     => ' D  !   ' , default => 1 ;
    has newline  => ' N  !   ' , default => 1 ;
    has context  => ' C  =i  ' , default => 100 , alias => 'U';
    has colormap => ' cm =s@ ' , default => [] ;
    has plain    => ' p      ' ,
	action   => sub {
	    $_->date = $_->newline = 0;
	};

    has '+help' => action => sub {
	pod2usage
	    -verbose  => 99,
	    -sections => [ qw(SYNOPSIS VERSION) ];
    };

    has '+version' => action  => sub {
	print "Version: $version\n";
	exit;
    };

} no Getopt::EX::Hashed;

my %colormap = qw(
    APPEND	K/544
    DELETE	K/544
    OCHANGE	K/445
    NCHANGE	K/445
    OTEXT	K/455E
    NTEXT	K/554E
    );

use Getopt::EX::Colormap qw(ansi_code);
my %termcap = pairmap { $a => ansi_code($b) }
    qw(
	  home  {CUP}
	  clear {CUP}{ED2}
	  el    {EL}
	  ed    {ED}
     );

sub run {
    my $opt = shift;
    local @ARGV = @_;

    use Getopt::EX::Long;
    Getopt::Long::Configure(qw(bundling require_order));
    $opt->getopt or usage({status => 1});

    use Getopt::EX::Colormap;
    my $cm = Getopt::EX::Colormap
	->new(HASH => \%colormap)
	->load_params(@{$opt->colormap});

    if (@ARGV) {
	push @{$opt->exec}, [ @ARGV ];
    } else {
	@{$opt->exec} or pod2usage();
    }

    return  $opt->do_loop();
}

sub do_loop {
    my $opt = shift;

    use App::cdif::Command;
    my $old = App::cdif::Command->new(@{$opt->exec});
    my $new = App::cdif::Command->new(@{$opt->exec});

    my @default_diff = (
			qw(cdif --no-command --no-unknown),
			map { ('--cm', "$_=$colormap{$_}") } sort keys %colormap
		       );

    my @diffcmd = do {
	if ($opt->diff) {
	    use Text::ParseWords;
	    shellwords $opt->diff;
	} else {
	    ( @default_diff,
	      map  { $_->[1] }
	      grep { $_->[0] }
	      [   $opt->unit => '--unit=' . $opt->unit ],
	      [ ! $opt->mark => '--no-mark' ],
	      [ ! $opt->old  => '--no-old' ],
	      [ defined $opt->context => '-U' . $opt->context ],
	    );
	}
    };

    print $termcap{clear} if $opt->refresh;
    my $count = 0;
    my $refresh_count = 0;
    while (1) {
	$old->rewind;
	$new->update;
	my $data = execute(@diffcmd, $old->path, $new->path) // die "diff: $!\n";
	if ($data eq '') {
	    if ($opt->silent) {
		flush($new->date, "\r");
		next;
	    }
	    $data = $new->data;
	    $data =~ s/^/ /mg if $opt->mark;
	}
	$data .= "\n" if $opt->newline;
	if ($opt->refresh) {
	    $data =~ s/^/$termcap{el}/mg;
	    if ($refresh_count++ % $opt->refresh == 0) {
		print $termcap{clear};
	    }
	}
	print $new->date, "\n\n" if $opt->date;
	print $data;
	if ($opt->refresh and $opt->clear) {
	    flush($termcap{ed});
	}
    } continue {
	last if ++$count == $opt->count;
	($old, $new) = ($new, $old);
	sleep $opt->interval;
    }

    flush($termcap{el}) if $opt->refresh;
    return 0;
}

sub flush {
    use IO::Handle;
    state $stdout = IO::Handle->new->fdopen(fileno(STDOUT), "w") or die;
    $stdout->printflush(@_);
}

sub execute {
    use IO::File;
    my $pid = (my $fh = IO::File->new)->open('-|') // die "open: $@\n";
    if ($pid == 0) {
	open STDERR, ">&STDOUT" or die "dup: $!";
	close STDIN;
	exec @_ or warn "$_[0]: $!\n";
	exit 3;
    }
    binmode $fh, ':encoding(utf8)';
    my $result = do { local $/; <$fh> };
    for my $child (wait) {
	$child != $pid and die "child = $child, pid = $pid";
    }
    ($? >> 8) == 3 ? undef : $result;
}

######################################################################

=pod

=head1 NAME

watchdiff - repeat command and watch a difference

=head1 SYNOPSIS

watchdiff option -- command

Options:

	-r, --refresh:1     refresh screen count (default 1)
	-i, --interval=i    interval time in second (default 2)
	-c, --count=i       command repeat count (default 1000)
	-e, --exec=s        set executing commands
	-s, --silent        do not show same result
	-p, --plain         shortcut for --nodate --nonewline
	--[no]date          show date at the beginning (default on)
	--[no]newline       print newline result (default on)
	--[no]clear         clear screen after output (default on)
	--diff=command      diff command used to compare result
	--unit=unit         comparison unit (word/letter/char/mecab)

=head1 VERSION

Version 4.26

=head1 EXAMPLES

	watchdiff ifconfig -a

	watchdiff df

	watchdiff --silent df

	watchdiff --refresh 5 --noclear df

	watchdiff -sri1 -- netstat -sp icmp

	watchdiff -e uptime -e iostat -e df

	watchdiff -ps --diff 'sdif --no-command -U-1' netstat -S -I en0

	watchdiff -pc18i10r0 date; say tea is ready


=head1 DESCRIPTION

Use C<^C> to terminate.


=head1 AUTHOR

Kazumasa Utashiro

L<https://github.com/kaz-utashiro/sdif-tools>


=head1 LICENSE

Copyright 2014- Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<diff(1)>, L<cdif(1)>, L<sdif(1)>


=cut
