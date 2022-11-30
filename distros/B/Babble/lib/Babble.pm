package Babble;

use strictures 2;

our $VERSION = '0.090009';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Babble - EXPERIMENTAL Babel-like for perl

=head1 VERSION

0.090009

=head1 SYNOPSIS

If you're here for help dealing with changes in perl's signatures syntax,
look at L<App::sigfix>.

If you're here to try out Babble itself, you'll want to do

  use Babble::Filter qw(::CorePluginName External::Plugin::Name);

to have it rewrite your code on the fly, or

  perl -MBabble::Filter=::CorePluginName,External::Plugin::Name  \
    -0777 -pe babble lib/MyFile.pm >lib/MyFile.pmc

to rewrite for shipping.

Current core plugins are C<::CoreSignatures>, C<::State>, C<::DefinedOr>,
C<::PostfixDeref>, C<::SubstituteAndReturn> (C<s///r>), C<::Ellipsis>,
C<::PackageBlock>, C<::PackageVersion>, and C<::SKT> (which is a start on
rewriting L<Syntax::Keyword::Try>).  For an example of an external plugin,
see L<Method::Signatures::PP>.

Not for 'normal' use but still interesting, C<::Sigify> attempts to convert
simple @_ unrolls into signatures - best used on its own, followed by
applying L<App::sigfix> if you need the 5.22-5.26 oldsignatures style.

=head1 REPOSITORY

L<http://github.com/shadow-dot-cat/Babble/>

=head1 AUTHOR

Matt S Trout (mst) <mst@shadowcat.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Matt S Trout (mst).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
