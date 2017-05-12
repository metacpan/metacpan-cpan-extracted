package Data::Tubes::Plugin::Renderer;
use strict;
use warnings;
use English qw< -no_match_vars >;
our $VERSION = '0.736';

use Log::Log4perl::Tiny qw< :easy :dead_if_first >;

use Data::Tubes::Util qw< normalize_args shorter_sub_names >;
use Data::Tubes::Util qw< read_file_maybe >;
my %global_defaults = (
   input  => 'structured',
   output => 'rendered',
);

sub _resolve_template {
   my $args     = shift;
   my $template = read_file_maybe($args->{template});
   $template = read_file_maybe($template->($args))
     if ref($template) eq 'CODE';
   LOGDIE 'undefined template' unless defined $template;
   $template = $args->{template_perlish}->compile($template)
     unless ref $template;
   return $template if ref($template) eq 'HASH';
   LOGDIE 'invalid template of type ' . ref($template);
} ## end sub _resolve_template

sub _create_tp {
   my $args = shift;
   require Template::Perlish;
   return Template::Perlish->new(
      map { $_ => $args->{$_} }
      grep { defined $args->{$_} } qw< start stop variables >
   );
} ## end sub _create_tp

sub _rwtp_ntp_nt {
   my $args     = shift;
   my $input    = $args->{input};
   my $output   = $args->{output};
   my $tp       = $args->{template_perlish};
   my $template = _resolve_template($args) // LOGDIE 'undefined template';
   return sub {
      my $record = shift;
      $record->{$output} =
        $tp->evaluate($template, $record->{$input} // {});
      return $record;
   };
} ## end sub _rwtp_ntp_nt

sub _rwtp_ntp_t {
   my $args   = shift;
   my $itf    = $args->{template_input};
   my $input  = $args->{input};
   my $output = $args->{output};
   my $tp     = $args->{template_perlish};
   my $ctmpl =
     defined($args->{template}) ? _resolve_template($args) : undef;
   return sub {
      my $record = shift;
      my $template =
        defined($record->{$itf})
        ? _resolve_template(
         {
            template_perlish => $tp,
            template         => $record->{$itf}
         }
        )
        : ($ctmpl
           // die {message => 'undefined template', record => $record});
      $record->{$output} =
        $tp->evaluate($template, $record->{$input} // {});
      return $record;
   };
} ## end sub _rwtp_ntp_t

sub _rwtp_tp_nt {
   my $args   = shift;
   my $itpf   = $args->{template_perlish_input};
   my $input  = $args->{input};
   my $output = $args->{output};
   my $ctp    = $args->{template_perlish};
   my $ctmpl  = $args->{template} // LOGDIE 'undefined template';
   my $pctmpl = _resolve_template($args) if defined $ctmpl;
   return sub {
      my $record = shift;
      my $tp = $record->{$itpf} // $ctp;
      my $template =
        defined($record->{$itpf})
        ? _resolve_template({template_perlish => $tp, template => $ctmpl})
        : $pctmpl;
      $record->{$output} =
        $tp->evaluate($template, $record->{$input} // {});
      return $record;
   };
} ## end sub _rwtp_tp_nt

sub _rwtp_tp_t {
   my $args   = shift;
   my $itpf   = $args->{template_perlish_input};
   my $itf    = $args->{template_input};
   my $input  = $args->{input};
   my $output = $args->{output};
   my $ctp    = $args->{template_perlish};
   my $ctmpl  = $args->{template};
   my $pctmpl = defined($ctmpl) ? _resolve_template($args) : undef;
   return sub {
      my $record = shift;
      my $tp = $record->{$itpf} // $ctp;
      my $template =
        defined($record->{$itf}) ? _resolve_template(
         {
            template_perlish => $tp,
            template         => $record->{$itf}
         }
        )
        : (!defined($ctmpl))
        ? die({message => 'undefined template', record => $record})
        : defined($record->{$itpf})
        ? _resolve_template({template_perlish => $tp, template => $ctmpl})
        : $pctmpl;
      $record->{$output} =
        $tp->evaluate($template, $record->{$input} // {});
      return $record;
   };
} ## end sub _rwtp_tp_t

sub render_with_template_perlish {
   my %args = normalize_args(
      @_,
      [
         {
            %global_defaults,
            start     => '[%',
            stop      => '%]',
            variables => {},
            name      => 'render with Template::Perlish',
         },
         'template'
      ]
   );
   my $name = $args{name};

   $args{template_perlish} //= _create_tp(\%args);

   my $tpi = defined $args{template_perlish_input};
   my $ti  = defined $args{template_input};
   return
       ($tpi && $ti) ? _rwtp_tp_t(\%args)
     : $tpi ? _rwtp_tp_nt(\%args)
     : $ti  ? _rwtp_ntp_t(\%args)
     :        _rwtp_ntp_nt(\%args);
} ## end sub render_with_template_perlish

shorter_sub_names(__PACKAGE__, 'render_');

1;
