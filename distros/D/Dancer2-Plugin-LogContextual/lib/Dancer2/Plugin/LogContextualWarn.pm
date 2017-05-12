package Dancer2::Plugin::LogContextualWarn;

use strictures 2;

use Dancer2;
use Dancer2::Plugin;

use Dancer2::Plugin::AppRole::Helper;

our $VERSION = '1.152121'; # VERSION

# ABSTRACT: force all warns in a Dancer2 plack app to log_warn

#
# This file is part of Dancer2-Plugin-LogContextual
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


on_plugin_import { ensure_approle_s LogContextualWarn => @_ };

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::LogContextualWarn - force all warns in a Dancer2 plack app to log_warn

=head1 VERSION

version 1.152121

=head1 SYNOPSIS

    use Dancer2;

    use Dancer2::Plugin::LogContextual; # not needed if you bring your own L::C
    set lc_logger => MyLCLogger->new;

    use Dancer2::Plugin::LogContextualWarn;

    any '/' => sub {
        warn "aaaah"; # logs via L::C's log_warn (and so will every warn in
                      # the local() scope)
    };

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
