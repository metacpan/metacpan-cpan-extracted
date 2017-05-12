# ============================================================================
package Catalyst::Helper::Model::Maketext;
# ============================================================================

use strict;
use warnings;

use Path::Class;
use FindBin;

sub mk_compclass {
    my ($self, $helper) = @_;

    my %args = ();

    my $basedir = Path::Class::Dir->new( $FindBin::Bin, '..', 'lib');
    my $maketext_module = $helper->{app}.'::'.$helper->{name};

    my @path = split (/\:\:/,$maketext_module);
    my $file = pop @path;
    
    my $maketext_dir = $basedir->subdir( join '/', @path );
    my $maketext_file = $maketext_dir->file($file.'.pm');
    $maketext_dir->mkpath();
    
    $helper->render_file('maketextclass', $maketext_file->stringify, \%args);
    $helper->render_file('modelclass', $helper->{file}, \%args);
    
    return 1;
}

sub mk_comptest {
    my ($self, $helper) = @_;

    return $helper->render_file('modeltest', $helper->{test});
}

=encoding utf8

=head1 NAME

Catalyst::Helper::Model::Maketext - Helper for Maketext models

=head1 SYNOPSIS

    script/myapp_create.pl model Maketext Maketext

=head1 DESCRIPTION

Helper for the L<Catalyst> Maketext model.

=head1 ARGUMENTS

   ./script/myapp_create.pl model <model_name> Maketext

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

__maketextclass__
package [% app %]::[% name %];

use strict;
use warnings;
use parent qw(CatalystX::I18N::Maketext);

1;

__modelclass__
package [% class %];

use strict;
use warnings;
use parent qw(CatalystX::I18N::Model::Maketext);

1;

=head1 NAME

[% class %] - Maketext Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Maketext Catalyst model component.

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
