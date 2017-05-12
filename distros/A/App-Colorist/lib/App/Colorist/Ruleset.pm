package App::Colorist::Ruleset;
$App::Colorist::Ruleset::VERSION = '0.150460';
use Moose ();
use Moose::Exporter;

# ABSTRACT: Helper syntax for building colorist rulesets

Moose::Exporter->setup_import_methods(
    as_is => [ qw( ruleset rule ) ],
);

our $BUILDING_RULESET;

sub ruleset(&) {
    my $code = shift;

    $BUILDING_RULESET = [];
    $code->();
    
    my $r = $BUILDING_RULESET;
    undef $BUILDING_RULESET;

    return $r;
}

sub rule {
    my ($regex, @names) = @_;
    push @$BUILDING_RULESET, $regex, \@names;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Colorist::Ruleset - Helper syntax for building colorist rulesets

=head1 VERSION

version 0.150460

=head1 SYNOPSIS

  ruleset {
      rule qr{Starting (\S+)\.\.\.}, qw( message program );
      rule qr{Finished processing (http://([\w.]+)/) \.\.\.}, qw( 
          message url hostname
      );
  }

=head1 DESCRIPTION

This defines a special syntax that may be used in ruleset configuration files for defining a ruleset.

=head1 DIRECTIVES

=head2 ruleset

  ruleset {
      # rules go in here ...
  }

There may only be exactly one C<ruleset> per ruleset configuration and all L</rule> directives must be placed inside it.

=head2 rule

  rule qr{Starting (\S+)\.\.\.}, qw( message program );

Within a L</ruleset>, there may be zero or more C<rule> directives. Each is given a regular expression to be used to match against a single line of text. Every match starts with an implicit "^" and ends with an implicit "$", so it must match an entire line.

After the regular expression, you must include a list of color names to assign each part of the match. This list must have at least one element in it, which is used for the entire line match. There must also be one for each group of parenthesis in the regular expression.

It is perfectly acceptable to use nested matches. As of this writing, there must be a fixed number of group matches, though. If you need to match groups like C<< (...)* >>, there's no way to name them at this time, so don't do that.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
