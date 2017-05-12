package App::SimpleScan::Plugin::LinkCheck;

$VERSION = '1.03';

use warnings;
use strict;
use Carp;

use Scalar::Util qw(looks_like_number);
use Text::Balanced qw(extract_quotelike extract_multiple);

sub import {
  no strict 'refs';
  *{caller() . '::_do_has_link'}   = \&_do_has_link;
  *{caller() . '::_do_no_link'}    = \&_do_no_link;
  *{caller() . '::link_condition'} = \&link_condition;
  *{caller() . '::_link_conditions'} = \&_link_conditions;
  *{caller() . '::_add_link_condition'} = \&_add_link_condition;

  *{caller() . '::_extract_quotelike_args'} = 
    \&_extract_quotelike_args;
}

sub pragmas {
  return ['has_link', \&_do_has_link],
         ['no_link',  \&_do_no_link],
         ['forget_link', \&_do_forget_link],
         ['forget_all_links', \&_do_forget_all];
}

sub init {
  my($class, $app) = @_;
  $app->{Link_conditions} = {};
}

sub _do_forget_all {
  my($self, $args) = @_;
  $self->{Link_conditions} = {};
}

sub _do_forget_link {
  my($self, $args) = @_;
  my @links = $self->_extract_quotelike_args($args);
  for my $link (@links) {
    delete $self->{Link_conditions}->{$link};
  }
}

sub _do_has_link {
  my($self, $args) = @_;
  my($name, $compare, $count);
  if (!defined $args) {
    $self->stack_code( qq(fail "No arguments for %%has_link";\n) );
    $self->test_count( $self->test_count() + 1 );
    return;
  }
  else {
    # Extract strings and backticked strings and just plain words.
    # We explicitly junk anything past the first three items.
    ($name, $compare, $count) = $self->_extract_quotelike_args($args);
  }
  $self->_add_link_condition( { name=>$name, compare=>$compare, count=>$count } );
}

sub _do_no_link {
  my($self, $args) = @_;
  if (!defined $args) {
    $self->stack_code( qq(fail "No arguments for %%no_link";\n) );
    $self->test_count( $self->test_count() + 1 );
  }
  else {
    my ($name) = $self->_extract_quotelike_args($args);
    $self->_do_has_link(qq($name == 0));
  }
}

sub _link_conditions {
  my ($self) = shift;
  return wantarray ? @{ $self->{Link_conditions} } : $self->{Link_conditions};
}

sub _add_link_condition {
  my ($self, $condition) = @_;
  push @{ $self->{Link_conditions}->{ $condition->{name} } }, $condition;
}

sub filters {
  return \&filter;
}

sub filter {
  my($self, @code) = @_;
  # If we've recursed because of the stack_code in this method, just exit.

  return unless defined $self->_link_conditions;
  my $test_count = 0;

  for my $link_name (keys %{$self->_link_conditions()} ) {
    for my $link_condition ( @{ $self->{Link_conditions}->{$link_name} } ) {
      my $compare = $link_condition->{compare};
      my $count   = $link_condition->{count};
      my $name    = $link_condition->{name};
  
      my $not_bogus = 1;
      my %have_a;

      # name alone is "at least one link with this name"
      if (defined $name and (! defined $compare) and (! defined $count) ) {
        $compare = ">";
        $count   = "0";
      }

      # Name is always defined, or we'd never have gotten here.
      $name = _dequote($name);

      # comparison is always defined: either we fixed it just above (because
      # it was missing altogether), or it's there (but possibly bad).
      if (! grep {$compare eq $_} qw(== > < >= <= !=) ) {
        push @code, qq(fail "$compare is not a legal comparison operator (use < > <= >= == !=)";\n);
        $test_count++;
        $not_bogus = 0;
      }

      if (!defined($count)) {
        push @code, qq(fail "Missing count";\n);
        $test_count++;
        $not_bogus = 0;
      }
      elsif (! looks_like_number($count) ) {
        push @code, qq(fail "$count doesn't look like a legal number to me";\n);
        $test_count++;
        $not_bogus = 0;
      }

      if ($not_bogus) {
        my $last_testspec  = $self->get_current_spec;
        $last_testspec->comment( qq('$name' link count $compare $count) );

        push @code, qq(cmp_ok scalar \@{[mech()->find_all_links(text=>qq($name))]}, qq($compare), qq($count), "'$name' link count $compare $count";\n);
        $test_count++;
        @code = _snapshot_hack($self, @code);
      }
    }
  }
  $self->test_count($self->test_count() + $test_count);
  return @code;
}

sub _snapshot_hack {
  # Snapshot MUST be called for every test stacked.
  my ($self, @code) = @_;
  if ($self->can('snapshot')) {
    return &App::SimpleScan::Plugin::Snapshot::filter($self, @code);
  }
  else {
    return @code;
  }
}

sub _extract_quotelike_args {
  # Extract strings and backticked strings and just plain words.
  my ($self, $string) = @_;

  # extract_quotelike complains if no quotelike strings were found.
  # Shut this up.
  no warnings;

  # The result of the extract multiple is to give us the whitespace
  # between words and strings with leading whitespace before the
  # first word of quotelike strings. Confused? This is what happens:
  #
  # for the string
  #   a test `backquoted' "just quoted"
  # we get
  #   'a'
  #   ' '
  #  'test'
  #  ' `backquoted'
  #  `backquoted`
  #  ' '
  #  ' "just'
  #  '"just quoted"'
  #
  # We do NOT use grep because if one of the arguments evaluates to 
  # zero, it won't get saved.
  my @wanted;
  foreach my $item 
    (extract_multiple($string, [qr/[^'"`\s]+/,\&extract_quotelike])) {
    push @wanted, _dequote($item) if $item !~ /^\s/;
  }
  return @wanted;
}

sub _dequote {
  my $string = shift;
  $string = eval $string if $string =~ /^(['"]).*(\1)$/;
  return $string;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan::Plugin::LinkCheck - Link counting/presence/absence plugin 


=head1 VERSION

This document describes App::SimpleScan::Plugin::LinkCheck version 1.00


=head1 SYNOPSIS

    # After this plugin is installed:
    %%has_link 'My stuff'
    %%no_link  'Send email'

    # The has_link and no_link checks will run for every test spec.
    http://someplace.com /foo/ Y Got my page
    http://someplace.com/subpage /foo/ Y Got my subpage

    # Stop checking for the 'My stuff' link
    %%forget_link 'My stuff'

    # Now only the "no 'Send email' link' test will run.
    http://someplace.com/map  /foo/ Y Get map page

    # More specific tests can be done:
    # The page will have exactly one 'home' link
    %%has_link 'Home' == 1

    # The page will have a non-zero number of 'offsite' links.
    %%has_link 'offsite' > 0

    http://someplace.com/links /foo/ Y Get links page
    # Now both these tests and the 'send email' test will run.

  
=head1 DESCRIPTION

Th Linkcheck plugin adds simple link counting and presence/absence
checking pragmas to C<simple_scan>. These pragmas are assertions;
they will be run for every test spec occurring after the pragma(s)
appear in the intput file.

You can, for instance, assert that you do not want to see a link
named 'Click here' anywhere in the pages referenced by the test
specs in this test:

  %%no_link 'Click here' 

Additional test specs generated by variable substitution will
each have the check made, so for example

  %%which bar baz quux
  http://<which>.foo.com  /foo.com/ Y   Fetch page

would check for /foo.com/ on each of bar.foo.com, 
baz.foo.com, and quux.foo.com, and also check for zero links
whose name is 'Click here' on each of these pages.

Conversely, you can assert that a link must be present on
each page you look at:

  %%has_link 'back'

This means that a link named 'back' must appear on every page
you fetch after this pragma occurs in the input.

You may want to remove the condition for some pages in your
tests; this can easily be done by 'forgetting' the link:

  %%forget_link 'back'

The assertion has now been dropped, and will not be tested
through the rest of the file. If you want to forget all of
the currently-active link-count assertions, just use

  %%forget_all_links

and all of the link checks will stop.

If you want to be more specific about the link counts, 
you can use the extended syntax for '%%has_link':

  %%has_link 'beta' >= 0
  %%has_link 'up' == 2
  %%has_link 'report_problems' != 1

Note that you can use any of the I<numeric> operators and
a count for this. These work just like the other tests, in
that they apply to every test spec following until either
the end of the file, or a '%%forget_link' that drops them.

=head1 INTERFACE 

=head2 init

Sets up the initial (empty) link conditions.

=head2 pragmas

Exports the definitions of C<has_link> and C<no_link> to C<simple_scan>.

=head2 filters

Returns list of output filter subs to caller (standard callback).

=head2 filter

Determines what (if any) link checks are queued up and stackes them,
incrementing the test count appropriately.

=head1 DIAGNOSTICS

=over

=item C<< %s is not a legal comparison operator (use < > <= >= == !=) >>

You supplied a comparison operator that wasn't one we expected.

=item C<< %s doesn't look like a legal number to me >>

The item you supplied as a count of the number of times you expect to 
see the link was not something that looks like a number to Perl.

=back


=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan::Plugin::LinkCheck requires no configuration files or environment variables.


=head1 DEPENDENCIES

App::SimpleScan.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan-plugin-linkcheck@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Yahoo! and 
Joe McMahon C<< <mcmahon@yahoo-inc.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
