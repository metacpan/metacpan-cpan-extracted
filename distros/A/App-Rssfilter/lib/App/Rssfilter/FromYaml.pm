# ABSTRACT: create App::Rssfilter objects from YAML configuration

use strict;
use warnings;


package App::Rssfilter::FromYaml;
{
  $App::Rssfilter::FromYaml::VERSION = '0.07';
}

use Moo::Role;
use Method::Signatures;
use YAML::XS;
requires 'from_hash';


method from_yaml( $config ) {
    $self->from_hash( Load( $config ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::FromYaml - create App::Rssfilter objects from YAML configuration

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    {
        package Cool::Name;
        use Role::Tiny::With;
        with 'App::Rssfilter::FromYaml';

        sub new { ... }
        sub add_group { ... }
        sub add_feed { ... }
        sub add_rule { ... }
    };


    my $cool_name = Cool::Name->from_yaml(<<"End_Of_Yaml");
    name: some group

    rules:
    # add_rule will be called with ...
    - keyvalue_pair: some value
    # then ...
    - this_hashref: of options
      with_multiple: keys and values

    feeds:
    # same as rules above
    # mix elements as you please
    - keyword_pair_for_first_feed: and value
    - keyword_pair_for_second_feed: with different value
    - feed_option1: more key-value pairs
      feed_option2: which will be passed as arguments
      feed_option3: for the third call to add_feed

    groups:

    - name: a subgroup
    - # subgroups can have their own feeds, rules, and subgroups
    - feeds:
      - ...
    - rules:
      - ...
    - groups:
      - ...

    - name: 'another subgroup',
    - feeds:
      - ...
    - rules:
      - ...
    - groups:
      - ...
    End_Of_Yaml

=head1 DESCRIPTION

This role will extend its receiving class with a L</from_yaml> method. It requires that the receiver has C<add_group>, C<add_feed>, and C<add_rule> methods, and accepts a C<name> attribute to its constructor.

=head1 METHODS

=head2 from_yaml

    my $receiver_instance = Receiver::Class->from_yaml( $config );

Create a new instance of the receiving class (using the top-level C<name> in C<$config> as its name), then create subgroups and add feeds or rules to it (or its subgroups).

C<$config> may have four keys:

=over 4

=item *

C<name>   - name of this group

=item *

C<groups> - list of associative arrays for subgroups, same schema as the original config

=item *

C<feeds>  - list of feeds to fetch

=item *

C<rules>  - list of rules to apply

=back

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
