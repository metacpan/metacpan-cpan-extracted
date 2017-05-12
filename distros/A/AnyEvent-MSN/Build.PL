use Module::Build;
Module::Build->new(
       dist_author        => 'Sanko Robinson <sanko@cpan.org>',
       module_name        => 'AnyEvent::MSN',
       license            => 'artistic_2',
       build_requires     => {'Test::More' => 0},
       configure_requires => {'Module::Build' => 0.38},
       requires           => {
                    perl              => '5.012',
                    AnyEvent          => '5.31',
                    'AnyEvent::HTTP'  => '2.1',
                    'MIME::Base64'    => '3.13',
                    'Moose'           => '2.0002',
                    'Try::Tiny'       => '0.09',
                    'XML::Twig'       => '3.38',
                    'Digest::HMAC'    => '1.02',
                    'Digest::SHA'     => '5.61',
                    'Digest::MD5'     => '2.51',
                    'Crypt::CBC'      => '2.30',
                    'Crypt::DES'      => '2.05',
                    'Crypt::DES_EDE3' => '0.01'
       },
       recursive_test_files => 1,
       meta_merge           => {
           keywords    => [qw[MSN client MSNP21 IM instant message Windows Live Messenger WLM]],
           resources => {
               bugtracker => 'http://github.com/sanko/anyevent-msn/issues',
               repository => 'http://github.com/sanko/anyevent-msn/',
               ChangeLog  => 'http://github.com/sanko/anyevent-msn/commits',
               license => 'http://www.perlfoundation.org/artistic_license_2_0'
           }
       }
)->create_build_script;

=pod

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2011 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with Microsoft.

=cut
