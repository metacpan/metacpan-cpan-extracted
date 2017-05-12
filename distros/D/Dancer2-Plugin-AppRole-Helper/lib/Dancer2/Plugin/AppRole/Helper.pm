package Dancer2::Plugin::AppRole::Helper;

use strictures 2;

our $VERSION = '1.152121'; # VERSION

# ABSTRACT: helper functions for creating Dancer2 AppRole plugins

#
# This file is part of Dancer2-Plugin-AppRole-Helper
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


use parent 'Exporter';

our @EXPORT = qw(ensure_approle ensure_approle_s);


sub ensure_approle {
    my ( $role, $dsl ) = @_;
    my $app = $dsl->app;
    return if $app->does( $role );
    Moo::Role->apply_roles_to_object( $app, $role );
}


sub ensure_approle_s { ensure_approle "Dancer2::Plugin::AppRole::" . shift, @_ }

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::AppRole::Helper - helper functions for creating Dancer2 AppRole plugins

=head1 VERSION

version 1.152121

=head1 SYNOPSIS

In your plugin:

    package Dancer2::Plugin::Mine;

    use Dancer2::Plugin;
    use Dancer2::Plugin::AppRole::Helper;

    # short version
    on_plugin_import { ensure_approle_s "Mine", @_ };

    # OR long and/or customized version
    on_plugin_import { ensure_approle "Dancer2::Plugin::AppRole::Mine", @_ };

    # ...

In your Dancer module:

    package MyDancerApp;

    use Dancer2;

    use Dancer2::Plugin::Mine; # loads and applies the role to the app object
    use Dancer2::Plugin::Mine; # does *not* do it again

    use MyDancerSubModule;

In a submodule:

    package MyDancerSubModule;

    use Dancer2 appname => 'MyDancerApp';

    use Dancer2::Plugin::Mine; # does *not* do it again either, but would if
                               # the submodule is loaded on its own

=head1 FUNCTIONS

=head2 ensure_approle

Apply the given role to the app in the given Dancer2 DSL object, but don't
apply it twice.

=head2 ensure_approle_s

Same as ensure_approle, but C<Dancer2::Plugin::AppRole::> is prepended on the
role name for shorter calling.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dancer2-Plugin-AppRole-Helper>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Dancer2-Plugin-AppRole-Helper>

  git clone https://github.com/wchristian/Dancer2-Plugin-AppRole-Helper.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
