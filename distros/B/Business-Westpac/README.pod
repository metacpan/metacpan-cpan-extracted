package Business::Westpac;

=head1 NAME

Business::Westpac - Top level namespace for the Business::Westpac
set of modules

=head1 VERSION

0.02

=head1 DESCRIPTION

Business::Westpac is a set of libraries for parsing/generating files
for use with Westpac bank as documented at
L<https://paymentsplus.westpac.com.au/docs/>

Note that this distribution is a work in progress or, if you prefer,
"incomplete" - we started working on it under the expectation of Westpac
being our banking partner but ended up going with another one so have
effectively abandoned development on this. It has been uploaded to
CPAN/github for anyone else to use/extended/fork/etc.

=head1 Do Not Use This Module Directly

You should go to the relevant module for the file format you want to
work with.

=cut

$Business::Westpac::VERSION = '0.02';

=head1 SEE ALSO

L<Business::Westpac::PaymentsPlus::Australian::Payment::Import::File>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-westpac

=cut

1;
