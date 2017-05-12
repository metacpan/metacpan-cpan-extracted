
package CSV::Template;

use strict;
use warnings;

our $VERSION = '0.03';

use base "HTML::Template";

sub quote_string {
    my ($self, $string) = @_;
    # escape embedded double 
    # quotes as two quotes
    $string =~ s/"/""/g; 			# "
    # since this is being called
    # we assume the do want to
    # quote the string
    return ('"' . $string . '"');
}

sub output {
    my ($self) = @_;
    my $output = $self->SUPER::output();
    # remove any blank lines
    # intentional blank lines 
    # should have one comma in them
    return join "\n" => grep {
            !/^\s*?$/
           } split /\n/ => $output;
}

1;

__END__

=head1 NAME

CSV::Template - A CSV templating module derived from HTML::Template

=head1 SYNOPSIS

  use CSV::Template;

  my $csv = CSV::Template->new(filename => "templates/test.tmpl");

  $csv->param(report_title => $csv->quote_string('My "Report"'));
  $csv->param(report_data => [
            { one => 1, two => 2, three => 3 },
            { one => 2, two => 4, three => 6 },
            { one => 3, two => 6, three => 9 },     
          ]);

  print $csv->output();

=head1 DESCRIPTION

This is really just a subclass of B<HTML::Template> that does some minor post processing of the output. Since B<HTML::Template> really just operates on plain text, and not HTML specifically, it dawned on me that there is no reason why I should not use B<HTML::Template> (and all my B<HTML::Template> friendly data structures) to generate my CSV files as well. 

Now this is by no means a full-features CSV templating system. Currently it serves my needs which is to display report output in both HTML (with B<HTML::Template>) and in CSV (to be viewed in Excel). 

=head1 METHODS

It is best to refer to the B<HTML::Template> docs, we only implement one method here, and override another.

=over 4

=item B<quote_string ($string_to_quote)>

This method can be used to quote strings with embedded comma's (they must be quoted properly so as not to be confused with the comma delimiter). In addition it handles strings which themselves have embedded double quotes. It returns the quoted string.

=item B<output>

We do some post processing of the normal B<HTML::Template> output here to make sure our display comes out correctly, by basically removing any totally blank lines from our output.

The reason for this is that when writing code for a template it is more convient to do this:

  <TMPL_LOOP NAME="report_data">
  <TMPL_VAR NAME="one">,<TMPL_VAR NAME="two">,<TMPL_VAR NAME="three">,
  </TMPL_LOOP>

Than it is to have to do this:

  <TMPL_LOOP NAME="report_data"><TMPL_VAR NAME="one">,<TMPL_VAR NAME="two">,<TMPL_VAR NAME="three">,
  </TMPL_LOOP>

The first example would normally leave an extra line in the output as a consequence of formating our template code the way we did. The second example avoids that problem, but at the sacrifice of clarity (in my opinion of course). 

To remedy this problem, I decided that any empty lines should be removed from the output. If you desire a blank line in your output, then simply put a single comma on that line. Excel should see and understand this as a blank line (at least my copy does).

=back

=head1 CAVEAT

This module makes no attempt to automatically quote strings with embedded commas, that is the responsibilty of the user. More automated string handling is on my L<TO DO> list.

=head1 TO DO

This is really just a quick fix for now, it serves my current needs. But that is not to say that I cannot see the possibilites for more features.

=over 4

=item Add "width" features

It would be nice if we could pad lines to a constant width, so that all the lines were of equal length. This would be useful when using this to prepare files for insertion into a database, etc. It shouldnt be too hard to accomplish.

=item Automatic string handling features

I would like to handle this in the code, so the template author and creater of the data-structure do not have to. Unfortunately I don't know enough yet about the inner workings of HTML::Template to do that, so it will have to wait.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite. 

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 /CSV/Template.pm              100.0    n/a    n/a  100.0  100.0   47.4  100.0
 t/10_CSV_Template_test.t      100.0    n/a    n/a  100.0    n/a   52.6  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------ 
 Total                         100.0    n/a    n/a  100.0  100.0  100.0  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------ 

Keep in mind this module only overrides one method in HTML::Template, so there is not much to cover here.

=head1 OTHER CSV MODULES

There are also a number of other CSV related modules out there, here are a few of the more file/persistence-related that I looked at before eventually creating this module.

=over 4

=item B<DBD::CSV>

This was very much overkill for my needs, but maybe not for yours.

=item B<Tie::CSV_File>

This uses C<tie>, which I am not a fan of, to map arrays of arrays to a CSV file. It would not handle my HTML::Template data structures, but if that is not a requirement of yours, give it a look.

=back

=head1 SEE ALSO

=over 4

=item B<HTML::Template>

This module is a subclass of HTML::Template, so if you want to know how to use it you will need to refer to that module's excellent documentation.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

