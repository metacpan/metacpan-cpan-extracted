package App::perlfind::Plugin::SpecialPackages;
use strict;
use warnings;
use App::perlfind;
our $VERSION = '2.07';

App::perlfind->add_trigger(
    'matches.add' => sub {
        my ($class, $word, $matches) = @_;
        $$word =~ /^UNIVERSAL::/ && push @$matches, 'perlobj';
        $$word =~ /^CORE::/      && push @$matches, 'perlsub';
    }
);
1;
__END__

=pod

=head1 NAME

App::perlfind::Plugin::SpecialPackages - Plugin to find documentation for special Perl packages

=head1 SYNOPSIS

    # perlfind UNIVERSAL::isa
    # (runs `perldoc perlobj`)

=head1 DESCRIPTION

This plugin for L<App::perlfind> knows where special Perl packages like
C<UNIVERSAL::> and C<CORE::> are documented.

