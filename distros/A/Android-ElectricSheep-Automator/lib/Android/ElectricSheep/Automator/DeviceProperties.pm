package Android::ElectricSheep::Automator::DeviceProperties;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Mojo::Log;
use Config::JSON::Enhanced;
use XML::XPath;
use XML::LibXML;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

use overload ( '""'  => \&toString );

sub new {
	my $class = $_[0];
	my $params = $_[1] // {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $self = {
		'_private' => {
			'logger-object' => undef,
			'verbosity' => 0,
			'mother' => 0,
		},
		'data' => {
			# corresponds to dumpsys->RawSurfaceWidth,RawSurfaceHeight
			'w' => 0,
			'h' => 0,
			'orientation' => 0,
			'density' => 0,
			'density-x' => 0,
			'density-y' => 0,
			'serial' => '<na>'
		}
	};
	bless $self => $class;

	if( exists $params->{'logger-object'} ){ $self->{'_private'}->{'logger-object'} = $params->{'logger-object'} } else { $self->{'_private'}->{'logger-object'} = Mojo::Log->new() }
	if( exists $params->{'verbosity'} ){ $self->{'_private'}->{'verbosity'} = $params->{'verbosity'} } else { $self->{'_private'}->{'verbosity'} = Mojo::Log->new() }
	# we now have a log and verbosity

	my $log = $self->log;
	my $verbosity = $self->verbosity;

	# we need a mother object (Android::ElectricSheep::Automator)
	if( (! exists $params->{'mother'})
	 || (! defined $params->{'mother'})
	 || (! defined $params->{'mother'}->adb())
	){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, input parameter 'mother' with our parent Android::ElectricSheep::Automator object was not specified."); return undef }
	$self->{'_private'}->{'mother'} = $params->{'mother'};

	# caller can specify some initial data to load
	# else caller must run ->enquire() to enquire the real device
	if( exists $params->{'data'} ){
		my $d = $self->{'data'}; 
		my $p = $params->{'data'};
		for my $k (sort keys %$d){
			if( exists($p->{$k}) && defined($p->{$k}) ){
				if( $self->set($k, $p->{$k}) ){ $log->error("${whoami} (via $parent), line ".__LINE__." : error, call to ".'set()'." has failed for input parameter '$k', is its type as expected (".ref($d->{$k}).")?"); return undef }
			}
		}
	}

	return $self;
}

# does a adb shell dumpsys and reads various things from it
# it may also do a adb shell wm density
# returns 0 on success, 1 on failure
sub enquire {
	my ($self, $params) = @_;
	$params //= {};

        my $parent = ( caller(1) )[3] || "N/A";
        my $whoami = ( caller(0) )[3];

	my $log = $self->log;
	my $verbosity = $self->verbosity;

	# first get the serial of the device
	my @cmd = ('get-serialno');
	my $res = $self->adb->run(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nsSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }
	$self->set('serial', $res->[1]=~s/\s*$//gmr); # it has a newline at the end

	# here we could also save to a file on device and then
	# fetch it locally. We will do that if there are problems
	# getting the dump from STDOUT
	@cmd = qw/dumpsys window/;
	$res = $self->adb->shell(@cmd);
	if( ! defined $res ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, got undefined result, most likely shell command did not run at all, this should not be happening."); return 1 }
	if( $res->[0] != 0 ){ $log->error(join(" ", @cmd)."\n${whoami} (via $parent), line ".__LINE__." : error, above shell command has failed, with:\nsSTDOUT:\n".$res->[1]."\n\nSTDERR:\n".$res->[2]."\nEND."); return 1 }

	if( $res->[1] =~ /PinnedStackController.+?mDisplayInfo=DisplayInfo\{.+?\breal\b\s*(\d+)\s*x\s*(\d+)/s ){
		$self->set('w', $1);
		$self->set('h', $2);
	} else { $log->error("DUMPSYS:\n".$res->[1]."\nEND DUMPSYS\n${whoami} (via $parent), line ".__LINE__." : error, failed to find screen size in above dumpsys."); return 1 }

	if( $res->[1] =~ /PinnedStackController.+?mDisplayInfo=DisplayInfo\{.+?\bdensity\s+(\d+)\s+\((.+?)\s*x\s*(.+?)\)\s+dpi/s ){
		$self->set('density', $1);
		$self->set('density-x', $2);
		$self->set('density-y', $3);
	} else { $log->error("DUMPSYS:\n".$res->[1]."\nEND DUMPSYS\n${whoami} (via $parent), line ".__LINE__." : error, failed to find screen density in above dumpsys."); return 1 }

	if( $res->[1] =~ /DisplayFrames w=.+?r=(\d+)/ ){
		$self->set('orientation', $1);
	} else { $log->error("DUMPSYS:\n".$res->[1]."\nEND DUMPSYS\n${whoami} (via $parent), line ".__LINE__." : error, failed to find orientation in above dumpsys."); return 1 }

	return 0; # success
}

sub get { return $_[0]->has($_[1]) ? $_[0]->{'data'}->{$_[1]} : undef }
sub set {
	# set a new value even if it is not in our store,
	# but if it is, then check the types match
	if( exists($_[0]->{'data'}->{$_[1]})
	 && (ref($_[2]) ne ref($_[0]->{'data'}->{$_[1]}))
	){ $_[0]->log()->error(__PACKAGE__."::set(), line ".__LINE__." : error, the type of parameter '$_[1]' is '".ref($_[2])."' but '".ref($_[0]->{'data'}->{$_[1]})."' was expected."); return 1 }
	$_[0]->{'data'}->{$_[1]} = $_[2];
	return 0; # success
}
sub has { exists $_[0]->{'data'}->{$_[1]} }

sub toString {
	return perl2dump($_[0]->{'data'}, {terse=>1});
#	my $self = $_[0];
#	my $ret = "";
#	for my $k (sort keys %{$self->{'data'}}){
#		my $v = $self->get($k);
#		$ret .= $k . '=' . (ref($v)eq'' ? $v : '['.join(',', @$v).']')."\n";
#	}
#	return $ret;
}

sub toJSON { return perl2json($_[0]->{'data'}, {pretty=>1}); }
sub TO_JSON { return $_[0]->{'data'} } 

sub log { return $_[0]->{'_private'}->{'logger-object'} }
sub verbosity { return $_[0]->{'_private'}->{'verbosity'} }
sub mother { return $_[0]->{'_private'}->{'mother'} }
sub adb { return $_[0]->mother->adb }

# only pod below
=pod

=head1 NAME

Android::ElectricSheep::Automator - The great new Android::ElectricSheep::Automator!

=head1 VERSION

Version 0.06


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Android::ElectricSheep::Automator;

    my $foo = Android::ElectricSheep::Automator->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1



=head2 function2


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-android-adb-automator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Android-ADB-Automator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Android::ElectricSheep::Automator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Android-ADB-Automator>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Android-ADB-Automator>

=item * Search CPAN

L<https://metacpan.org/release/Android-ADB-Automator>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Android::ElectricSheep::Automator
