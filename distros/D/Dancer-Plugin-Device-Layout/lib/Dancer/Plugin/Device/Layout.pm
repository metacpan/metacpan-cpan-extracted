package Dancer::Plugin::Device::Layout;
############################################################################
# Dancer::Plugin::Device::Layout - Dancer v1 plugin Dancer::Plugin::Device::Layout dynamically changes layout to match user agent's best layout.
# @author     BURNERSK <burnersk@cpan.org>
# @license    http://opensource.org/licenses/artistic-license-2.0 Artistic License 2.0
# @copyright  © 2013, BURNERSK. Some rights reserved.
############################################################################
use strict;
use warnings FATAL => 'all';
use utf8;

BEGIN {
  use version 0.77; our $VERSION = version->new('v0.1');
}

use Dancer 1.3111 qw( :syntax );
use Dancer::Plugin;
use HTTP::BrowserDetect 1.51;

############################################################################
sub device_layout {
  my ( $self, %args ) = plugin_args(@_);

  # Load plugin settings and defined defaults.
  my $conf = plugin_setting;
  $conf->{normal_layout}    //= 'normal';
  $conf->{mobile_layout}    //= 'mobile';
  $conf->{tablet_layout}    //= 'tablet';
  $conf->{no_tablet}        //= 0;
  $conf->{tablet_as_mobile} //= 0;
  $conf->{no_mobile}        //= 0;

  my $request   = request;
  my $browser   = HTTP::BrowserDetect->new( $request ? $request->user_agent : q{} );
  my $is_tablet = $browser->tablet ? 1 : 0;
  my $is_mobile = $browser->mobile ? 1 : 0;

  # Diagnostics.
  if ( $args{override_device} ) {
    if ( $args{override_device} eq 'normal' ) {
      $is_tablet = $is_mobile = 0;
    }
    elsif ( $args{override_device} eq 'tablet' ) {
      $is_tablet = $is_mobile = 1;
    }
    elsif ( $args{override_device} eq 'mobile' ) {
      $is_tablet = 0;
      $is_mobile = 1;
    }
  }

  my $device_layout = $conf->{normal_layout};
  if ( $is_tablet && !$conf->{no_tablet} ) {
    $device_layout = $conf->{tablet_layout};

    # treat tablet as mobile.
    if ( $conf->{tablet_as_mobile} ) {
      $device_layout = $conf->{mobile_layout};
    }
  }
  elsif ( $is_mobile && !$conf->{no_mobile} ) {
    $device_layout = $conf->{mobile_layout};
  }

  return wantarray ? ( layout => $device_layout ) : $device_layout;
}
register device_layout => \&device_layout;

############################################################################
register_plugin;

############################################################################
1;
__END__
=pod

=encoding utf8

=head1 NAME

Dancer::Plugin::Device::Layout - Dancer v1 plugin
Dancer::Plugin::Device::Layout dynamically changes layout to match user
agent's best layout.

=head1 VERSION

This documentation describes L<Dancer::Plugin::Device::Layout> v0.1.

=head1 SYNOPSIS

    package MyApp;
    use Dancer ':syntax';
    use Dancer::Plugin::Device::Layout;
    
    get '/' => sub {
      my $tokens = {};
      my $options = { device_layout };
      template 'index', $tokens, $options;
    };

=head1 DESCRIPTION

L<Dancer::Plugin::Device::Layout> was invented to extend YANICK's
L<Dancer::Plugin::MobileDevice> with tablet detection.

=head1 SUBROUTINES/METHODS

=head2 device_layout

Returns context sensetive layout information.

    # Returns ( layout => 'normal' )
    my $options = { device_layout };
    
    # Returns 'normal'
    my $display_layout = device_layout;

=head1 DIAGNOSTICS

L</device_layout> does have diagnostic functionality. It takes a hash to
override some internal values.

=over

=item override_device =E<gt> normal|tablet|mobile

Ignores the user agent and assume user agent is as provided.

=back

=head1 CONFIGURATION AND ENVIRONMENT

L<Dancer::Plugin::Device::Layout> uses L<Dancer>'s
L<config system|Dancer::Config> to configure itself.

Extend your C<config.yml> like this:

    plugins:
      Device::Layout:
        normal_layout:    normal
        mobile_layout:    mobile
        tablet_layout:    tablet
        no_tablet:        0
        tablet_as_mobile: 0
        no_mobile:        0

=over

=item normal_layout: LAYOUT

The normal layout when user agent is nighter a tablet nor a mobile device.
Default is 'main'.

=item mobile_layout: LAYOUT

The mobile layout when user agent is a mobile but not a tablet device.
Default is 'mobile'.

=item tablet_layout: LAYOUT

The tablet layout when user agent is a tablet device. Default is 'tablet'.

=item no_tablet: 1|0

Disable tablet detection. Default is '0'.

=item tablet_as_mobile: 1|0

Treat tablet as mobile devices. Default is C<undef>.

=item no_mobile: 1|0

Disable mobile detection. Default is '0'.

=back

=head1 DEPENDENCIES

=over

=item L<strict>

=item L<warnings>

=item L<utf8>

=item L<version> 0.77 or higher

=item L<Dancer> 1.3111 or higher (B<not> 2.x)

=item L<Dancer::Plugin>

=item L<HTTP::BrowserDetect> 1.51 or higher

=back

=head1 INCOMPATIBILITIES

Currently there are no incompatibilities known.

=head1 BUGS AND LIMITATIONS

Currently there are no bugs or limitations known. Please report bugs at
L<GitHub Issues|https://github.com/burnersk/Dancer-Plugin-Device-Layout/issues>.

=head1 AUTHOR

=over

=item

BURNERSK L<burnersk@cpan.org|mailto:burnersk@cpan.org>

=back

=head1 LICENSE

Dancer::Plugin::Device::Layout by BURNERSK is licensed under a
L<Artistic License 2.0 License|http://opensource.org/licenses/artistic-license-2.0>.

=head1 COPYRIGHT

Copyright © 2013, BURNERSK. Some rights reserved.

=cut
