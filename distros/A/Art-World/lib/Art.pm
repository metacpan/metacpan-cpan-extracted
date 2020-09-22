package Art {

    use Zydeco;

    include Abstractions;

    class Abstract with Abstractions {
        has idea;
        has process;
        has file;
        has discourse;
        has time;
        has project;


    }

    include Artwork;

}

1;


=encoding UTF-8

=head1 NAME

Art - TODO

=head1 SYNOPSIS

  TODO

=head1 DESCRIPTION

=head1 AUTHORS

=over

=item Sébastien Feugère <sebastien@feugere.net>

=item Seb. Hu-Rillettes <shr@balik.network>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2020 Seb. Hu-Rillettes

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=cut
