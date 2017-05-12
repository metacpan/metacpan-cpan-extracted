package App::Test::Tapat;

use Moose;

=head1 NAME

App::Test::Tapat - An automated testing framework

=head1 VERSION

Version 0.04

Please note that this should be considered a developer release.

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

This module is designed to be a framework for automated testing.

    use App::Test::Tapat;
   
    # New Tapat object 
    my $t = App::Test::Tapat->new;

    # Chop up test into consituent test bits
    $t->filename($test_file);
    print "-> Running $t->{test_name} at $time_now with test id: $t->{test_id}\n";

    # Parse the test for TAP and output results
    $t->parsetest($test_file);

=cut

has 'test_name' => (isa => 'Str', is => 'rw', default => 0);
has 'script' => (isa => 'Str', is => 'rw', default => 0);
has 'test_id' => (isa => 'Int', is => 'rw', default => 0);

=head1 DESCRIPTION

Tapat aims to be an automated testing framework. It currently only provides a 
mechanism  to run tests which contain TAP, receive the test's output, and 
relay that output further to a report and, in the future, a database.

Tapat is designed to be programming language agnostic. This means that you can 
write tests in any language that can produce TAP, and many languages can, 
including perl, python, php, bash, C/C++, Java, various SQL implementations, 
ruby, and any language that can create simple TAP output. (See the TAP wiki.) 
Once your tests are written, they are run by the tapat harness and reports 
are created.

The goal is to allow testers to focus on their testing, not the mechanism or framework 
that surrounds their tests, enabling a simple drop-in mechanism for new automated 
tests to run inside of. So with Tapat, you get a parsing and reporting layer for
your tests.

=head1 METHODS

=head2 filename

Calling filename returns the name of the test script that will be parsed for
TAP. It returns three constituent elements of the test file which will be used
later: test_name, test_id and script. These constituent elements are built into
the test name merely by convention. A test ought to have a name of test_1, (that
is to say; alphanumeric characters followed by an underscore, followed by an
integer.) This allows one to sort tests numerically and it is also what Tapat 
expects. As previously mentioned, it is only a convention, but hopefully a 
useful one.

=cut

sub filename {
 
  my ($self, $file) = @_;
  $file = fileparse($file);
  my ($script, $test_id) = split /_/, $file;
  $self->script($script) || confess "Not sure how to assign script.";
  $self->test_id($test_id) || confess "Not sure how to assign test_id.";
  $self->test_name($file) || confess "Not sure how to assign filename.";
}

=head2 parsetest

This is where the TAP from your test gets parsed. A timer is created here as
well.

=cut

sub parsetest {
  use TAP::Parser qw/all/;
  use TAP::Parser::Aggregator qw/all/;
  use Term::ANSIColor;
  use File::Basename;

  my ($self, $file) = @_;
  my $planned = 0;
  my $aggregate = TAP::Parser::Aggregator->new;

  # Create parser object
  my $parser = TAP::Parser->new( { source => $file } );
  $aggregate->start();            # start timer
  $aggregate->add($file, $parser);

  while ( my $result = $parser->next ) {
    my $out = $result->as_string;
    print "$out\n";
    if ($result->is_plan) {
      $planned = $result->tests_planned;
    }
  }
  $aggregate->stop();             # stop timer

  my $elapsed = $aggregate->elapsed_timestr();
  my $failed = $parser->failed;
  my $passed = $parser->passed;

  # If we ran all the tests, and they all passed
  if ($parser->is_good_plan && ($passed - $failed == $planned)) {
    print color 'green'; 
    print "\n--==[ Passed all our planned tests, updating db for $self->{test_id} ]==--\n";
  } else {
    print color 'red';
    print "\n--==[ ERROR in testing output. ]==--\n";
  }
  print "Elapsed time: $elapsed\nPassed: $passed\nFailed: $failed\n---\n";
  print color 'reset';
}


=head1 AUTHOR

Jeremiah C. Foster, C<< <jeremiah at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-test-tapat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Test-Tapat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Test::Tapat


You can also look for information at:

=over 4

=item * Tapat's homepage on source forge

L<http://tapat.sourceforge.net>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Test-Tapat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Test-Tapat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Test-Tapat>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Test-Tapat>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to the Moose team, rjbs for Module::Starter, the TAP team, and Alias
for giving us all a goal to aspire to.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Jeremiah C. Foster, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Test::Tapat
