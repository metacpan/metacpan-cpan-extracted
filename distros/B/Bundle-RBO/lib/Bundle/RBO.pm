package Bundle::RBO;

our $VERSION = '0.00001';

1;
__END__

=head1 NAME

Bundle::RBO - A bundle to install all of RBO's favorite modules


=head1 Synopsis

    # debian / ubuntu
    apt-get install libreadline-dev

    perl -MCPAN -e 'install Bundle::RBO'

=head1 Description

This bundle contains all of RBO's most-used CPAN modules. These
are essentials whenever he builds a new system.

=head1 CONTENTS

App::Ack

App::cpanminus

DBI

DBIx::Class

DBIx::Class::Schema::Loader

DBIx::Class::ResultSet::HashRef

Dist::Zilla::PluginBundle::RBO

JSON

DateTime

IO::All

JSON

Module::Build

Module::Install

Moose

Template

Template::Provider::FromDATA

Term::ReadLine::Gnu

local::lib

YAML

LWP

=head1 AUTHOR

Robert Bohne <rbo@cpan.org>

=head1 License

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
