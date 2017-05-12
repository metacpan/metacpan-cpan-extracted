package App::perlfind::Plugin::UseModule;
use strict;
use warnings;
use App::perlfind;
our $VERSION = '2.07';

App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;
        # does it look like a package name?
        return unless $$word =~ /^\w+(::\w+)*$/;
        my $try_module = sub {
            my $module = shift;
            eval "use $module;";
            return 0 if $@;
            push @$matches, $module;
            return 1;
        };

        # try it as a module
        return if $try_module->($$word);

        if ($$word =~ /::[A-Z]\w*$/) {
            push @$matches, $$word;
        } elsif ($$word =~ s/::\w+$//) {
            $try_module->($$word);
        }
    }
);
1;
__END__

=pod

=head1 NAME

App::perlfind::Plugin::UseModule - Try the search word as a module name

=head1 SYNOPSIS

    # perlfind Getopt::Long

=head1 DESCRIPTION

This plugin for L<App::perlfind> tries to use the search term as a module name.
If the module can be loaded, it is added to the match results.

If it contains '::', it might be a fully qualified function name such as
C<Foo::Bar::some_function> or a module that's not installed but whose
namespace-parent might be installed. For example, if C<Foo::Bar> is installed
but C<Foo::Bar::Baz> isn't, we don't want think that there is a function
C<Baz()> in the package C<Foo::Bar>; rather we want to show the docs for
C<Foo::Bar::Baz>. To distinguish between a function and a module, use a simple
heuristic, which means it's a guess and won't always work: if the final symbol
starts with an uppercase character, we assume it's a package, otherwise we
assume it's a function.
