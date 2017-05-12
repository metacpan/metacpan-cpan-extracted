package Acme::PlayCode::Plugin::Averything;

use Moose::Role;
use Path::Class ();

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:FAYLAND';

use vars qw/$avreything_loaded/;

around 'play' => sub {
    my $orig = shift;
    my $self = shift;

    $avreything_loaded = 0 unless (defined $avreything_loaded);
    unless ( $avreything_loaded ) {
        my @all_plugins;
        my $path = __FILE__;
        $path =~ s/Averything\.pm//isg;
        my $dir = Path::Class::Dir->new($path);
        my $handle = $dir->open;
        while (my $file = $dir->next) {
            $file = $file->stringify;
            next if ( $file !~ /\.pm$/ );
            ( undef, my $basename ) = ( $file =~ /^(.*?)Plugin\S(.*?)$/is );
            $basename =~ s/\.pm$//isg;
            $basename =~ s/[\\\/]/\:\:/isg;
            next if ( $basename eq 'Averything');
            push @all_plugins, $basename;
        }
        @all_plugins = sort @all_plugins;
        $self->load_plugins(@all_plugins);
        $avreything_loaded = 1;
    }

    $orig->($self, @_);
};

no Moose::Role;

1;
__END__

=head1 NAME

Acme::PlayCode::Plugin::Averything - A is Ace, All, Averything

=head1 SYNOPSIS

    use Acme::PlayCode;
    
    my $app = new Acme::PlayCode;
    
    # load all plugins we find at the dir of this module sits.
    $app->load_plugin('Averything');
    
    my $played_code = $app->play( $code );
    # or
    my $played_code = $app->play( $filename );
    # or
    $app->play( $filename, { rewrite_file => 1 } ); # override $filename with played code

=head1 DESCRIPTION

Load all plugins find at lib/Acme/PlayCode/Plugin/.

=head1 SEE ALSO

L<Acme::PlayCode>, L<Moose>, L<PPI>, L<MooseX::Object::Pluggable>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
