use 5.010;
use strict;
use warnings;
package Acme::Gtk2::Ex::Builder;
BEGIN {
  $Acme::Gtk2::Ex::Builder::VERSION = '0.008';
}
# ABSTRACT: Funny Gtk2 Interface Design Module

use base qw( Exporter );

our @EXPORT  = qw(
    build
    contain
    info
    on
    prop
    set
    widget
);

sub find {
    my $self   = shift;
    my $id     = shift;
    my $widget = shift;
 
    if ($widget) {
        $self->{_widget}{$id} = $widget;
    }
 
    return $self->{_widget}{$id};
}
 
sub _current {
    my $self = shift;
    my $up   = shift || 0;
    $self->{_current}[-1 - $up];
}
 
sub _current_push {
    my $self   = shift;
    my $widget = shift;
    push @{ $self->{_current} }, $widget;
}
 
sub _current_pop {
    my $self = shift;
    pop @{ $self->{_current} };
}
 
sub contain (&) { @_ }
 
sub build (&) {
    my $code = shift;
 
    my $self = bless {
        _info    => {},
        _widget  => {},
        _current => [],
    }, __PACKAGE__;
 
    no strict 'subs';
    no warnings 'redefine';
 
    local *_widget = sub ($&) {
        my $class  = shift;
        my $_code  = shift;
        my @params = @_;
 
        my $widget;
        if (ref($class) && $class->isa("Gtk2::Widget")) {
            $widget = $class;
        }
        else {
            $widget = "Gtk2::$class"->new(@params);
        }
 
        if ($self->_current && ref($self->_current) ne __PACKAGE__) {
            given (ref $self->_current) {
                when (/Gtk2::VBox|Gtk2::HBox/) {
                    $self->_current->pack_start($widget, 0, 0, 1);
                }
                default {
                    $self->_current->add($widget);
                }
            };
        }
 
        $self->_current_push( $widget );
 
        local *_info = sub {
            my $key    = shift;
            my @values = @_;
 
            given ($key) {
                when ('id') {
                    $self->find($values[0], $self->_current);
                }
                when ('packing') {
                    given (ref $self->_current(1)) {
                        when (/Gtk2::VBox|Gtk2::HBox/) {
                            $self->_current(1)->set_child_packing($self->_current, @values);
                        }
                    }
                }
                default {
                }
            }
            $self->{_info}{$self->_current}{$key} = \@values;
        };
 
        local *_on = sub {
            my $signal = shift;
            my $_code  = shift;
            my $data   = shift;
 
            if ($self->_current) {
                $self->_current->signal_connect( $signal => $_code, $data );
            }
        };
 
        local *_set = sub {
            my $attr = shift;
            my @para = @_;
 
            my $method = "set_$attr";
            if ($self->_current) {
                $self->_current->$method(@para);
            }
        };

        local *_prop = sub {
            my $prop  = shift;
            my $value = shift;
 
            my $method = "set";
            if ($self->_current) {
                $self->_current->$method($prop, $value);
            }
        };
 
        $_code->() if defined $_code;
        $self->_current_pop;
    };
 
    $code->();
 
    return $self;
}
 
sub _warn {
    my $syntax = shift;
    sub { warn "you cannot call '$syntax' directly" };
}
 
*_widget = _warn 'widget';
*_info   = _warn 'info';
*_on     = _warn 'on';
*_set    = _warn 'set';
*_prop   = _warn 'prop';
 
sub widget { goto &_widget }
sub info   { goto &_info   }
sub on     { goto &_on     }
sub set    { goto &_set    }
sub prop   { goto &_prop   }

1;


=pod

=encoding utf-8

=head1 NAME

Acme::Gtk2::Ex::Builder - Funny Gtk2 Interface Design Module

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Gtk2 -init;
    use Acme::Gtk2::Ex::Builder;
    
    my $app = build {
        widget Window => contain {
            info id           => 'window';
            set  title        => 'Awesome App';
            set  default_size => 200, 100;
            set  position     => 'center';
            on   delete_event => sub { Gtk2->main_quit; };
    
            widget Button => contain {
                set label  => 'Action';
                on clicked => sub { say 'Seoul Perl Mongers!' };
            };
        };
    };
    
    $app->find('window')->show_all;
    Gtk2->main;

=head1 METHODS

=head2 find

Find and get widget by ID.
You can find widget only you set C<id> with C<info> function.

    my $app = build {
        widget Window => contain {
            info id => 'my-window';
        };
    };
    
    my $window = $app->find('my-window');

=head1 FUNCTIONS

=head2 build

This function acts like ordinary "new" method.
It is exported by default and returns L<Acme::Gtk2::Ex::Builder> object.
It can contains several C<widget> functions.

    my $app = build {
        widget Window;
        widget Dialog;
        widget FileChooser;
        widget VBox;
    };

=head2 widget

This function creates the Gtk2 widget.
In fact when you use this, C<< Gtk2::XXX->new >> will be called.
See L<Gtk2> and Gtk2 API reference.

Following code will call C<< Gtk2::Window->new >>.

    my $app = build {
        widget Window;
    };

If you need more children widgets,
use C<contain>, then call C<widget> again and again.

    my $app = build {
        widget Window contain => {
            widget HBox => contain {
                widget Button;
                widget Button;
                widget Button;
            };
        };
    };

If you have to use more parameters for constructor,
then specify additional parameters after the C<widget> block.
Following code create L<Gtk2::SimpleList> with
additional C<timestamp>, C<nick> and C<message> parameter.
See L<Gtk2> and Gtk2 API reference.

    use Gtk2;
    use Gtk2::SimpleList; # Do NOT forgot!!
    
    my $app = build {
        widget SimpleList => contain {
            info id              => 'logviewer';
            set  headers_visible => FALSE;
            set  rules_hint      => TRUE;
        }, (
            timestamp => 'markup',
            nick      => 'markup',
            message   => 'markup',
        );
    };

It also supports prebuilt widget.

    my $prev_button = Gtk2::Button->new('Prev');
    my $next_button = Gtk2::Button->new('Next');
    my $quit_button = Gtk2::Button->new;
    
    my $app = build {
        widget VBox => contain {
            widget HBox => contain {
                widget $prev_button;
                widget $next_button;
            };
            widget $next_button => contain {
                info packing => TRUE, TRUE, 1, 'end';
                set  label   => 'quit';
                on   clicked => \&quit_clicked;
            }
        };
    };

=head2 info

This function sets additional information.
Since it is not realted to Gtk2 functions,
attributes, signal and properties,
so save anything what you want or need.

Currently C<id> and C<packing> have some special meanings.
C<id> is used for C<widget> method to find widget.
C<packing> is used for L<Gtk2::VBox> and L<Gtk2::HBox>.

    my $app = build {
        widget Window => contain {
            info id             => 'window';
            set  title          => 'Seoul.pm irc log viewer';
        };
    
        widget HBox => contain {
            info id      => 'hbox';
            info packing => TRUE, TRUE, 1, 'start';
    
            widget ScrolledWindow => contain {
                set policy => 'never', 'automatic';
            };
        };
    };

=head2 on

This function connects signals for specified widget.
Actually it is same as C<< $widget->signal_connect >>.
See L<Gtk2> and Gtk2 API reference.

    my $app = build {
        widget Window => contain {
            on   delete_event => sub { Gtk2->main_quit };
            widget VBox => contain {
                widget ToggleButton => contain {
                    set  label   => "show/hide";
                    on   toggled => \&toggled;
                };
                widget Button => contain {
                    set  label   => 'Quit';
                    on   clicked => sub { Gtk2->main_quit };
                };
            };
        };
    };

=head2 set

This function calls C<< $widget->set_KEY(VALUE) >> function
for specified widget.
See L<Gtk2> and Gtk2 API reference.

    my $app = build {
        widget Window => contain {
            set  title        => 'Awesome App';
            set  default_size => 200, 100;
            set  position     => 'center';
        };
    };

=head2 prop

This function sets properties for specified widget.
Actually it is same as C<< $widget->set(KEY, VALUE) >>.
See L<Gtk2> and Gtk2 API reference.

    my $app = build {
        widget Window => contain {
            info id               => 'window';
            set  position         => 'center';
            prop title            => 'Window Example';
            prop opacity          => 0.8;
            prop 'default-width'  => 640;
            prop 'default-height' => 480;
            on   delete_event     => \&quit;
        };
    };

=head2 contain

This function is used to set attributes, set properties,
connect signal, add additional information or contain children widgets.

    my $app = build {
        widget Window => contain {
            info   ...
            set    ...
            prop   ...
            on     ...
            widget ...
        };
    };

=head1 SEE ALSO

The idea of this module is stealed from
L<Seoul.pm Perl Advent Calendar, 2010-12-24|http://advent.perl.kr/2010-12-24.html>.
I think L<Gtk2::Ex::Builder> will be released someday by the article's author.
But before the release, this module colud be helpful for you
who likes L<Gtk2> but too lazy to type all code by his/her own hands.

=head1 AUTHOR

Keedi Kim - 김도형 <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

