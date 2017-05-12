use strict ;

# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; package CGI::Builder::Conf
; use Carp
; $Carp::Internal{+__PACKAGE__}++
; $Carp::Internal{__PACKAGE__.'::_'}++  
; use IO::Util


; use Class::constr
        { default   => \&CGI::Builder::Conf::_::default
        , init      => \&CGI::Builder::_::init
        , no_strict => 1
        }

; use Class::groups
  ( { name    => 'conf_mml_options'
    , default => { optional => 1
                 , filter   => { qr/.+/ => 'TRIM_BLANKS' }
                 }
    }
  )

; *conf_option = \&conf_mml_options
  
; use Object::props 'conf_file'

; sub CGI::Builder::Conf::_::default
   { my ($s, %args) = @_
   ; my $file = $args{conf_file} || $s->conf_file or return {}
   ; my $opt  = $args{conf_mml_options} || $s->conf_mml_options
   ; my (%defaults, $sub)
   ; $sub = sub
             { my ($res, $h) = @_
             ; foreach my $k ( keys %$h )
                { $$res{$k} = ref $$h{$k} eq 'HASH'
                              ? $sub->($$res{$k}, $$h{$k})
                              : $$h{$k}
                }
             ; $res
             }
   ; foreach my $conf ( ref $file eq 'ARRAY' ? @$file : $file )
      { $sub->( \%defaults, IO::Util::load_mml( $conf, $opt ) )
      }
   ; \%defaults
   }

; 1

__END__

=pod

=head1 NAME

CGI::Builder::Conf - Add user editable configuration files to your WebApp

=head1 SYNOPSIS

  use CGI::Builder
  qw| CGI::Builder::Conf
    | ;
  
  # in the instance script
  $webapp = My::WebApp->new( conf_file => '/path/to/conf_file.mml' )
  $webapp = My::WebApp->new( conf_file => [ '/path/to/conf_file.mml',
                                            '/other_conf_file.mml' ]
                           , conf_mml_options => .... )
  
  # optionally in the CBB
  My::WebApp->conf_mml_options ( .... );   # IO::Util::load_mml options

=head1 DESCRIPTION

This Extension adds another way to pass arguments to the new method: a user editable MML file (see L<IO::Util/"Minimal Markup Language (MML)">). This is useful when you want to give to other people (e.g. your client) the possibility to configure their own application instance, but you don't want to give them the possibility to edit and run a potentially unsecure perl script.

You can do so by passing to the new method the full path to a list of C<conf_file>; the mixed structure of their data will be loaded as the default arguments for that instance (see L<Class::constr/"OPTIONS">).

B<Important Note>: Please notice that the data contained in the C<conf_file> is tainted however, so treat that with care (e.g. as they were query parameters).

=head1 PROPERTY AND GROUP ACCESSORS

=head2 conf_file

This property access and sets the full path to the MML configuration files. You can pass a single path or a list of paths: in that case the data in the next file will override the previous one. You will usually set it with the C<new()> method or by overriding the property.

=head2 conf_mml_options

This is a Class property group accessor, which allows you to define the C<IO::Util::load_mml> options used to load the C<conf_file>. By default it has a true C<optional> option (i.e. it won't croak for missing C<conf_file>), and a 'TRIM_BLANKS' filter.

=head2 conf_options

Deprecated alias for C<conf_mml_options>.

=head1 SUPPORT

See L<CGI::Builder/"SUPPORT">.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
