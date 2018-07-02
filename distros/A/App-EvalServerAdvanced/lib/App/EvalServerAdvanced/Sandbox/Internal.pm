package App::EvalServerAdvanced::Sandbox::Internal;
our $VERSION = '0.023';

use strict;
use warnings;

use App::EvalServerAdvanced::Config;
use Module::Runtime qw/require_module check_module_name/;
use Moo;

sub load_plugins {
  my $load_module = sub {
    my ($name) = @_;
    check_module_name($name);

    if ($name !~ /^App::EvalServerAdvanced::Sandbox::Plugin::/) {
      do {
        local @INC = config->sandbox->plugin_base;
        return $name if (eval {require_module($name)});
      };
      # we couldnt' load it from the plugin base, try from @INC with a fully qualified name
      my $fullname = "App::EvalServerAdvanced::Sandbox::Plugin::$name";
      return $fullname if (eval {require_module($fullname)});

      die "Failed to find plugin $name";
    } else {
      return $name if (eval {require_module($name)});

      die "Failed to find plugin $name";
    }
  };

  with map {$load_module->($_)} config->sandbox->plugins->@*;
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

App::EvalServerAdvanced::Sandbox::Internal

=head1 SYNOPSIS

This is an internal class used as part of the plugin system for the sandbox.  This is where all the plugin roles for the sandbox end up.

=head1 CUSTOM LANGUAGE PROCESSING
When configuring the server and setting up a language, you can create a function that looks like the following:

    sub run_perl {
        my( $class, $lang, $code ) = @_;
        ...
    }

The first argument C<$class> is pretty much useless.  It will always be C<App::EvalServerAdvanced::Sandbox::Internal>,
as your subroutine is called as a dynamic method call.

In the configuration you can setup the language thusly,

    [language.perl]
    sub="deparse_perl"
    seccomp_profile="lang_perl"

That subroutine, C<deparse_perl>, will then be called and told the name of the language, and the code so you can do whatever
processing is needed.

=head1 TEMPLATING CODE

You can also use this to template the code being passed to an external interpreter.

    sub perl_wrap {
        my ($class, $lang, $code) = @_;
        my $qcode = quotemeta $code;

        my $wrapper = 'use Data::Dumper;

        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Quotekeys = 0;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Useqq = 1;

        my $val = eval "#line 1 \"(IRC)\"\n'.$qcode.'";

        if ($@) {
          print $@;
        } else {
          $val = ref($val) ? Dumper ($val) : "".$val;
          print " ",$val;
        }
        ';
        return $wrapper;
    }

And in the configuration of the EvalServer

    [language."perl5.8"]
    bin="/perl5/perlbrew/perls-5.8.9/bin/perl"
    args=["-e", "%CODE%"]
    wrap_code="perl_wrap"
    seccomp_profile="lang_perl"

This lets you manipulate the code before it's passed to the interpreter and make any changes necessary.

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=cut
