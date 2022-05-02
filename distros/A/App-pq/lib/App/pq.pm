package App::pq;

1;

=head1 NAME

App::pq - Like jq and gq, but with Perl

=head1 SYNOPSIS

With no arguments, dump the JSON data structure from STDIN as a Perl data structure.

    $ echo '{"foo":[1,2,3],"bar":"blee"}' | pq
    $VAR1 = {
              'bar' => 'blee',
              'foo' => [
                         1,
                         2,
                         3
                       ]
            };

With an argument, process the argument as code with $j as the perl data structure.

    $ echo '{"foo":[1,2,3],"bar":"blee"}' | pq 'print join "\n",  keys %$j'
    foo
    bar

=head1 AUTHOR

Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> ( Blog: L<http://symkat.com/> )

=head1 COPYRIGHT

Copyright (c) 2022 the WebService::WsScreenshot L</AUTHOR>, L</CONTRIBUTORS>, and L</SPONSORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AVAILABILITY

The most current version of App::pq can be found at L<https://github.com/symkat/App-pq>

