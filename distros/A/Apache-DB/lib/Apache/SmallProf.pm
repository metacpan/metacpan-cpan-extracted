package Apache::SmallProf;

use strict;
use vars qw($VERSION @ISA);
use Apache::DB 0.13;
@ISA = qw(DB);

$VERSION = '0.09';

$Apache::Registry::MarkLine = 0;

BEGIN { 
	use constant MP2 => eval { 
        exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} >= 2
    };
	die "mod_perl is required to run this module: $@" if $@; 

	if (MP2) { 
		require APR::Pool;
		require Apache2::RequestUtil;
		require Apache2::RequestRec;
		require Apache2::ServerUtil;
	}
}

sub handler {
    my $r = shift;
    my $dir;
    
    if (MP2) { 
        $dir = Apache2::ServerUtil::server_root(); 
    }
    else { 
        $dir = $r->server_root_relative; 
    }

    my $sdir = $r->dir_config('SmallProfDir') || 'logs/smallprof';
	$dir = "$dir/$sdir"; 

    # Untaint $dir 
    $dir =~ m/^(.*?)$/; $dir = $1; 

    mkdir $dir, 0755 unless -d $dir;

    # Die if we can't make the directory 
	die "$dir does not exist: $!" if !-d $dir; 

    (my $uri = $r->uri) =~ s,/,::,g;
    $uri =~ s/^:+//;

    my $db = Apache::SmallProf->new(file => "$dir/$uri", dir => $dir);
    $db->begin;

	if (MP2) { 
		$r->pool->cleanup_register(sub { 
		local $DB::profile = 0;
		$db->end;
		0;
		});
	}
	else { 
		$r->register_cleanup(sub { 
		local $DB::profile = 0;
		$db->end;
		0;
		});
	}
    0;
}

package DB;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;

    Apache::DB->init;

    $self;
}

use strict;
use Time::HiRes qw(time);
$DB::profile = 0; #skip startup profiles

sub begin {
    $DB::trace = 1;

    $DB::drop_zeros = 0;
    $DB::profile = 1;
    if (-e '.smallprof') {
	do '.smallprof';
    }
    $DB::prevf = '';
    $DB::prevl = 0;
    my($diff,$cdiff);
    my($testDB) = sub {
	my($pkg,$filename,$line) = caller;
	$DB::profile || return;
	%DB::packages && !$DB::packages{$pkg} && return;
    };

    # "Null time" compensation code
    $DB::nulltime = 0;
    for (1..100) {
	my($u,$s,$cu,$cs) = times;
	$DB::cstart = $u+$s+$cu+$cs;
	$DB::start = time;
	&$testDB;
	($u,$s,$cu,$cs) = times;
	$DB::cdone = $u+$s+$cu+$cs;
	$DB::done = time;
	$diff = $DB::done - $DB::start;
	$DB::nulltime += $diff;
    }
    $DB::nulltime /= 100;

    my($u,$s,$cu,$cs) = times;
    $DB::cstart = $u+$s+$cu+$cs;
    $DB::start = time;
}

sub DB {
    my($pkg,$filename,$line) = caller;
    $DB::profile || return;
    %DB::packages && !$DB::packages{$pkg} && return;
    my($u,$s,$cu,$cs) = times;
    $DB::cdone = $u+$s+$cu+$cs;
    $DB::done = time;

    # Now save the _< array for later reference.  If we don't do this here, 
    # evals which do not define subroutines will disappear.
    no strict 'refs';
    $DB::listings{$filename} = \@{"main::_<$filename"} if 
	defined(@{"main::_<$filename"});
    use strict 'refs';

    my $delta = $DB::done - $DB::start;
    $delta = ($delta > $DB::nulltime) ? $delta - $DB::nulltime : 0;
    $DB::profiles{$filename}->[$line]++;
    $DB::times{$DB::prevf}->[$DB::prevl] += $delta;
    $DB::ctimes{$DB::prevf}->[$DB::prevl] += ($DB::cdone - $DB::cstart);
    ($DB::prevf, $DB::prevl) = ($filename, $line);

    ($u,$s,$cu,$cs) = times;
    $DB::cstart = $u+$s+$cu+$cs;
    $DB::start = time;
}

use File::Basename qw(dirname basename);

sub out_file {
    my($self, $fname) = @_;
    if($fname =~ /eval/) {
	$fname = basename($self->{file}) || "smallprof.out";
    } 
    elsif($fname =~ s/^Perl.*Handler subroutine \`(.*)\'$/$1/) {
    }
    else {
	for (keys %INC) {
	    if($fname =~ s,.*$_,$_,) {
		$fname =~ s,/+,::,g;
		last;
	    }
	}
	if($fname =~ m,/,) {
	    $fname = basename($fname);
	}
    }
    return "$self->{dir}/$fname.prof";
}

sub end {
    my $self = shift;

    # Get time on last line executed.
    my($u,$s,$cu,$cs) = times;
    $DB::cdone = $u+$s+$cu+$cs;
    $DB::done = time;
    my $delta = $DB::done - $DB::start;
    $delta = ($delta > $DB::nulltime) ? $delta - $DB::nulltime : 0;
    $DB::times{$DB::prevf}->[$DB::prevl] += $delta;
    $DB::ctimes{$DB::prevf}->[$DB::prevl] += ($DB::cdone - $DB::cstart);

    my($i, $stat, $time, $ctime, $line, $file);

    my %cnt = ();
    foreach $file (sort keys %DB::profiles) {
	my $out = $self->out_file($file);
	open(OUT, ">$out") or die "can't open $out $!";
	if (defined($DB::listings{$file})) {
	    $i = -1;
	    foreach $line (@{$DB::listings{$file}}) {
		++$i or next;
		chomp $line;
		$stat = $DB::profiles{$file}->[$i] || 0 
		    or !$DB::drop_zeros or next;
		$time = defined($DB::times{$file}->[$i]) ?
		    $DB::times{$file}->[$i] : 0;
		$ctime = defined($DB::ctimes{$file}->[$i]) ?
		  $DB::ctimes{$file}->[$i] : 0;
		printf OUT "%10d %.6f %.6f %10d:%s\n", 
		$stat, $time, $ctime, $i, $line;
	    }
	} 
	else {
	    $line = "The code for $file is not in the symbol table.";
	    warn $line;
	    for ($i=1; $i <= $#{$DB::profiles{$file}}; $i++) {
		next unless 
		    ($stat = $DB::profiles{$file}->[$i] || 0 
		     or !$DB::drop_zeros);
		$time = defined($DB::times{$file}->[$i]) ?
		    $DB::times{$file}->[$i] : 0;
		$ctime = defined($DB::ctimes{$file}->[$i]) ?
		  $DB::ctimes{$file}->[$i] : 0;
		printf OUT "%10d %.6f %.6f %10d:%s\n", 
		$stat, $time, $ctime, $i, $line;
	    } 
	}
	close OUT;
    }
}

sub sub {
    no strict 'refs';
    local $^W = 0;

    goto &$DB::sub unless $DB::profile;

    if (defined($DB::sub{$DB::sub})) {
	my($m,$s) = ($DB::sub{$DB::sub} =~ /.+(?=:)|[^:-]+/g);
	$DB::profiles{$m}->[$s]++;
	$DB::listings{$m} = \@{"main::_<$m"} if defined(@{"main::_<$m"});
    }
    goto &$DB::sub;
}

1;
__END__

=head1 NAME

Apache::SmallProf - Hook Devel::SmallProf into mod_perl

=head1 SYNOPSIS

 <IfDefine PERLSMALLPROF>

    <Perl>
     use Apache::DB ();
     Apache::DB->init;
    </Perl>

    <Location />
     PerlFixupHandler Apache::SmallProf
    </Location>
 </IfDefine>

=head1 DESCRIPTION

Devel::SmallProf is a line-by-line code profiler.  Apache::SmallProf provides
this profiler in the mod_perl environment.  Profiles are written to
I<$ServerRoot/logs/smallprof> and unlike I<Devel::SmallProf> the profile is
split into several files based on package name.

The I<Devel::SmallProf> documentation explains how to analyize the profiles,
e.g.:

 % sort -nrk 2  logs/smallprof/CGI.pm.prof | more
         1 0.104736       629:     eval "package $pack; $$auto";
         2 0.002831       647:       eval "package $pack; $code";
         5 0.002002       259:    return $self->all_parameters unless @p;
         5 0.000867       258:    my($self,@p) = self_or_default(@_);
         ...

=head1 LICENSE 

This module is distributed under the same terms as Perl itself. 

=head1 SEE ALSO

Devel::SmallProf(3), Apache::DB(3), Apache::DProf(3)

=head1 AUTHOR

Devel::SmallProf - Ted Ashton
Apache::SmallProf derived from Devel::SmallProf - Doug MacEachern

Currently maintained by Frank Wiles <frank@wiles.org>
