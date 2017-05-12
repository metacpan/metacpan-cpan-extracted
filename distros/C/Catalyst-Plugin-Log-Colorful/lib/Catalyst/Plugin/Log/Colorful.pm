package Catalyst::Plugin::Log::Colorful;

use strict;
use vars qw($TEXT $BACKGROUND);
use Term::ANSIColor;
use Data::Dumper;

our $VERSION = '0.15';

sub setup {
    my $c = shift;

    my $config = $c->config->{'Plugin::Log::Colorful'} || $c->config->{log_colorful};
    $TEXT = $config->{text} || 'red' ;
    $BACKGROUND = $config->{background};

    if ( !$config->{on_backward_compatibility} ) {
        $c->log( Catalyst::Plugin::Log::Colorful::_::Log->new( { color_table => $config->{color_table} } ) ) ;
    }

    $c = $c->next::method(@_);
    return $c;
}

sub Catalyst::Log::color {
    my ( $s ,$var, $color , $bg_color ) = @_;

    # is not debug mdoe.
    return unless $s->is_debug;

    $color    = $color    || $Catalyst::Plugin::Log::Colorful::TEXT ;
    $bg_color = $bg_color || $Catalyst::Plugin::Log::Colorful::BACKGROUND ;

    if ( ref $var eq 'ARRAY' or ref $var eq 'HASH') {
        $var = Dumper( $var );
    }

    if ( $bg_color ) {
        $color .= " on_$bg_color";
    }

    $s->debug( color(  $color ) . $var .color('reset'));
}

package Catalyst::Plugin::Log::Colorful::_::Log;

use strict;
use warnings;
use base qw/Catalyst::Log/;
use Term::ANSIColor;
use Data::Dumper;
__PACKAGE__->mk_accessors(qw/color_table/);

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new();
    $self->{color_table} = $args->{color_table};
    return $self;
}
sub warn {
    my ( $s ,$var, $color , $bg_color ) = @_;
    return unless $s->is_warn;
    $color    = $color    || $s->{color_table}{warn}{color}    || 'yellow' ;
    $bg_color = $bg_color || $s->{color_table}{warn}{bg_color} ;
    $s->_colorful_log('warn', $var, $color , $bg_color );
}
sub error{
    my ( $s ,$var, $color , $bg_color ) = @_;
    return unless $s->is_error;
    $color    = $color    || $s->{color_table}{error}{color}    || 'red' ;
    $bg_color = $bg_color || $s->{color_table}{error}{bg_color} ;
    $s->_colorful_log('error', $var, $color , $bg_color );
}
sub fatal{
    my ( $s ,$var, $color , $bg_color ) = @_;
    return unless $s->is_fatal;
    $color    = $color    || $s->{color_table}{fatal}{color}    || 'white';
    $bg_color = $bg_color || $s->{color_table}{fatal}{bg_color} || 'red';
    $s->_colorful_log('fatal', $var, $color , $bg_color );
}
sub debug {
    my ( $s ,$var, $color , $bg_color ) = @_;

    return unless $s->is_debug;

    $color    = $color    || $s->{color_table}{debug}{color}    || 'black';
    $bg_color = $bg_color || $s->{color_table}{debug}{bg_color} || 'white';

    $s->_colorful_log('debug', $var, $color , $bg_color );
}
sub info {
    my ( $s ,$var, $color , $bg_color ) = @_;

    return unless $s->is_info;

    $color    = $color    || $s->{color_table}{info}{color}    ;
    $bg_color = $bg_color || $s->{color_table}{info}{bg_color} ;

    if ( $color ) {
        $s->_colorful_log('info', $var, $color , $bg_color );
    }
    else {
        $s->SUPER::info( $var );
    }
}

sub _colorful_log {
    my ( $s , $type, $var , $color , $bg_color ) = @_;

    if ( ref $var ) {
        $var = Dumper( $var );
    }

    if ( $bg_color ) {
        $color .= " on_$bg_color";
    }

    my $method = 'SUPER::' . $type;
    $s->$method( color(  $color ) . $var .color('reset'));
}

1
;

=head1 NAME

Catalyst::Plugin::Log::Colorful - Catalyst Plugin for Colorful Log

=head1 SYNOPSIS

 sub foo : Private {
     my ($self , $c  ) = @_;
     $c->log->debug('debug');
     $c->log->info( 'info');
     $c->log->warn( 'warn');
     $c->log->error('error');
     $c->log->fatal('fatal');

     $c->log->debug('debug' , 'red', 'white');
     $c->log->warn( 'warn' ,  'blue' );
 }

myapp.yml # default color is set but can change.

 'Plugin::Log::Colorful' :
    color_table :
        debug :
            color    : white
            bg_color : blue
        warn :
            color    : blue
            bg_color : green
        error :
            color    : red
            bg_color : yellow
        fatal :
            color    : red
            bg_color : green

=head1 DESCRIPTION

Sometimes when I am monitoring 'tail -f error_log' or './script/my_server.pl'
during develop phase, I could not find log message because of a lot of
logs. This plugin may help to find it out.  This plugin is using L<Term::ANSIColor>.

Of course when you open log file with vi or some editor, the color wont
change and also you will see additional log such as '[31;47moraora[0m'.

=head1 BACKWARD COMPATIBILITY

for new version I remove $c->log->color() but still you can use if you turn on on_backward_compatibility setting.

This plugin injects a color() method into the L<Catalyst::Log> namespace.

 use Catalyst qw/-Debug ConfigLoader Log::Colorful/;

 __PACKAGE__->config(
    name => 'MyApp' ,
    'Plugin::Log::Colorful' => {
        on_backward_compatibility => 1,
        text        => 'blue',
        background  => 'green',
    }
 );

In your controller.

 $c->log->color('hello');
 $c->log->color('hello blue' , 'blue');
 $c->log->color('hello red on white' , 'red' , 'white');
 $c->log->color( $hash_ref );
 $c->log->color( $array_ref );


=head1 METHOD

=head2 setup

=head1 SEE ALSO

L<Catalyst::Log>
L<Term::ANSIColor>

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=cut
