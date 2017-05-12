package Dancer2::Plugin::LogContextual;

use strictures 2;

use Dancer2;
use Dancer2::Plugin;

use Dancer2::Plugin::AppRole::Helper;

our $VERSION = '1.152121'; # VERSION

# ABSTRACT: wrap a Dancer2 plack app in the configured Log::Contextual logger

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


on_plugin_import { ensure_approle_s LogContextual => @_ };

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::LogContextual - wrap a Dancer2 plack app in the configured Log::Contextual logger

=head1 VERSION

version 1.152121

=head1 SYNOPSIS

    use Dancer2;

    use Dancer2::Plugin::LogContextual;
    use Log::Contextual ':log';

    any '/' => sub {
        log_error "aaaah"; # logs via lc_logger below
    };

    set lc_logger => MyLCLogger->new;

    my $app = to_app; # the logger above will now be active for every route
                      # dispatched by this app and every function called
                      # therein

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dancer2-Plugin-LogContextual>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Dancer2-Plugin-LogContextual>

  git clone https://github.com/wchristian/Dancer2-Plugin-LogContextual.git

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
