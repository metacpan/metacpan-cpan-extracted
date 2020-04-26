package App::GitGot::Types;
our $AUTHORITY = 'cpan:GENEHACK';
$App::GitGot::Types::VERSION = '1.337';
# ABSTRACT: GitGot type library
use 5.014;    ## strict, unicode_strings
use warnings;

use Type::Library
  -base ,
  -declare => qw/
                  GitWrapper
                  GotOutputter
                  GotRepo
                /;
use Type::Utils -all;
use Types::Standard -types;

class_type GitWrapper   , { class => "Git::Wrapper" };
class_type GotOutputter , { class => "App::GitGot::Outputter" };
class_type GotRepo      , { class => "App::GitGot::Repo" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitGot::Types - GitGot type library

=head1 VERSION

version 1.337

=head1 AUTHOR

John SJ Anderson <john@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
