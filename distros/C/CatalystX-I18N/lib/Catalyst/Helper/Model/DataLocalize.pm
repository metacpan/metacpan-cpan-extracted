# ============================================================================
package Catalyst::Helper::Model::DataLocalize;
# ============================================================================

use strict;
use warnings;

use Path::Class;
use FindBin;

sub mk_compclass {
    my ($self, $helper) = @_;

    my %args = ();

    my $basedir = Path::Class::Dir->new( $FindBin::Bin, '..', 'lib');
    my $datalocalize_module = $helper->{app}.'::'.$helper->{name};

    my @path = split (/\:\:/,$datalocalize_module);
    my $file = pop @path;
    
    my $datalocalize_dir = $basedir->subdir( join '/', @path );
    my $datalocalize_file = $datalocalize_dir->file($file.'.pm');
    $datalocalize_dir->mkpath();
    
    $helper->render_file('datalocalizeclass', $datalocalize_file->stringify, \%args);
    $helper->render_file('modelclass', $helper->{file}, \%args);
    
    return 1;
}

sub mk_comptest {
    my ($self, $helper) = @_;

    return $helper->render_file('modeltest', $helper->{test});
}

=encoding utf8

=head1 NAME

Catalyst::Helper::Model::DataLocalize - Helper for DataLocalize models

=head1 SYNOPSIS

    script/myapp_create.pl model DataLocalize DataLocalize

=head1 DESCRIPTION

Helper for the L<Catalyst> DataLocalize model.

=head1 ARGUMENTS

   ./script/myapp_create.pl model <model_name> DataLocalize

You need to sepecify the C<model_name> (the name of the model).

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    http://www.k-1.com

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__datalocalizeclass__
package [% app %]::[% name %];

use strict;
use warnings;
use parent qw(CatalystX::I18N::DataLocalize);

1;

__modelclass__
package [% class %];

use strict;
use warnings;
use parent qw(CatalystX::I18N::Model::DataLocalize);

1;

=head1 NAME

[% class %] - DataLocalize Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

DataLocalize Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 3;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');
use_ok('[% app %]::[% name %]');
