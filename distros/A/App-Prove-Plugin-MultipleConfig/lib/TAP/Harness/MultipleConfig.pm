package TAP::Harness::MultipleConfig;
use strict;
use warnings;

use parent 'TAP::Harness';

use ConfigCache;

sub new {
    my ($self, $params) = @_;
    $params->{callbacks} = +{
        after_test => sub {
            my ($filenames) = @_;
            my $config = ConfigCache->get_config_by_filename($filenames->[0]);
            ConfigCache->push_configs($config);
        },
    };
    $self->SUPER::new($params);
}

1;

__END__

=head1 NAME

TAP::Harness::MultipleConfig - TAP::Harness for MultipleConfig

=head1 DESCRIPTION

TAP::Harness::MultipleConfig is TAP::Harness for MultipleConfig.
After finishing each test, this module dissociate a pid with a filename.

=head1 LICENSE

Copyright (C) takahito.yamada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

takahito.yamada

=head1 SEE ALSO

L<prove>, L<App::Prove::Plugin::MySQLPool>

=cut
