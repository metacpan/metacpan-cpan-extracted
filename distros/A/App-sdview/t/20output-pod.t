#!/usr/bin/perl

use v5.26;
use warnings;
use experimental 'signatures';

use Test2::V0;

use App::sdview::Parser::Pod;
use App::sdview::Output::Pod;

sub dotest ( $name, $in_pod )
{
   my @p = App::sdview::Parser::Pod->new->parse_string( $in_pod );
   my $output = App::sdview::Output::Pod->new;
   my $out_pod = $output->generate( @p );

   is( $out_pod, $in_pod, "Generated POD for $name" );
}

dotest "Headings", <<"EOPOD";
=head1 Head1

=head2 Head2

Contents here
EOPOD

dotest "Formatting", <<"EOPOD";
=pod

B<bold> B<< <bold> >>

I<italic>

C<code> C<< code->with->arrows >>

F<filename>

L<link|target://> L<Module::Here>

U<underline>
EOPOD

dotest "Verbatim", <<"EOPOD";
=head1 EXAMPLE

    use v5.14;
    use warnings;
    say "Hello, world";
EOPOD

dotest "Bullet lists", <<"EOPOD";
=over 4

=item *

First

=item *

Second

=item *

Third

=back
EOPOD

dotest "Numbered lists", <<"EOPOD";
=over 4

=item 1.

First

=item 2.

Second

=item 3.

Third

=back
EOPOD

dotest "Definition lists", <<"EOPOD";
=over 4

=item First

The first item

=item Second

The second item

=item Third

The third item

Has two paragraphs

=back
EOPOD

done_testing;
