package App::perl2js;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";



1;
__END__

=encoding utf-8

=head1 NAME

App::perl2js - A module that transpile Perl code to JavaScript as readable as possible.

=head1 SYNOPSIS

    use App::perl2js::Converter;
    print App::perl2js::Converter->new->convert(q[
        package Hoge;
        sub hoge {
            my $self = $_[0];
            if ($_[1]) {
                $self->{hoge} = $_[1];
            } else {
                return $self->{hoge};
            }
        }
    ]);
    # ---- output ----
    # 'use strict';
    # function print() { console.log.apply(console.log, arguments) }
    # ... some runtime helplers
    #
    # var Hoge = (function() {
    #     var Hoge = {
    #         hoge() {
    #             if (this !== undefined) { Array.prototype.unshift.call(arguments, this) }
    #             var $self = arguments[0];
    #             if (arguments[1]) {
    #                 $self["hoge"] = arguments[1];
    #             } else {
    #                 return $self["hoge"]
    #             }
    #         },
    #     }
    #     return Hoge;
    # })();
    # export { Hoge }


=head1 DESCRIPTION

App::perl2js is a transpiler from Perl to JavaScript. this module aim to help porting from Perl to JavaScript, not to output runnable code.

=head1 LICENSE

Copyright (C) hatz48.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hatz48 E<lt>hatz48@hatena.ne.jpE<gt>

=cut
