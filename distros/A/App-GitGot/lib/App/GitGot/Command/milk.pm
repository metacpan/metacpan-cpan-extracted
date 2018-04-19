package App::GitGot::Command::milk;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Command::milk::VERSION = '1.336';
use 5.014;

# ABSTRACT: well, do you?
use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ milk / }

sub _execute {
        # Doesn't use 'cowsay' in case it's not installed
  print " ___________\n";
  print "< got milk? >\n";
  print " -----------\n";
  print "        \\   ^__^\n";
  print "         \\  (oo)\\_______\n";
  print "            (__)\\       )\\/\\ \n";
  print "                ||----w |\n";
  print "                ||     ||\n";
  print "\n";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Command::milk - well, do you?

=head1 VERSION

version 1.336

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
