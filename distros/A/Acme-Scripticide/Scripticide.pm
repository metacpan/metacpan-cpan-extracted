package Acme::Scripticide;

use strict;
use warnings;
use version;our $VERSION = qv('0.0.4');

use File::Spec;
use Carp;

sub import {
    $_[1]='' if !defined $_[1];
    *main::good_bye_cruel_world = *{Acme::Scripticide::good_bye_cruel_world} if $_[1] eq 'good_bye_cruel_world';
    good_bye_cruel_world($_[1], join(' ', @_[ 2 .. $#_ ])) if $_[1] ne 'good_bye_cruel_world';
}

sub good_bye_cruel_world {
    if(defined $_[0] && $_[0] =~ m/^\.\w+$/) {
        my $new = File::Spec->rel2abs($0);
        $new =~ s/\.\w+$//;
        open my $heart, '>', "$new$_[0]" or carp "'$new$_[0]' I have too much to live for, open: $!";
        print $heart $_[1];
        close $heart;
        unlink File::Spec->rel2abs($0) or carp "'$0' I have too much to live for, unlink: $!";
    }
    elsif(defined $_[0] && $_[0]) {
        my $note = join(' ', @_);
        open my $heart, '>', File::Spec->rel2abs($0) or carp "'$0' I have too much to live for, open: $!";
        print $heart $note;
        close $heart;
    }
    else {
        unlink File::Spec->rel2abs($0) or carp "'$0' I have too much to live for, unlink: $!";
    }
}

1;

__END__

=head1 NAME

Acme::Scripticide - Perl extension to allow your script to kill itself

=head1 SYNOPSIS

auto call good_bye_cruel_world()

   use Acme::Scripticide; 
 
auto call good_bye_cruel_world('Good bye cruel world')

   use Acme::Scripticide qw(Good bye cruel world);

auto put "Good bye cruel world" in [$0 w/out \.\w+$].html, call good_bye_cruel_world()

   use Acme::Scripticide ('.html', qw(Good bye cruel world)); 

only do it when and where you want

   use Acme::Scripticide qw(good_bye_cruel_world);

   if(i_take_medication_and_therapy()) {
       print "Take that Tom Cruise, you wacky weirdo, tell Jackson howdy.";
   }
   else {
       good_bye_cruel_world();
   }
 
=head2 EXPORT

None by default.

You can export good_bye_cruel_world and then it won't be automatically done, only when you call it.

=head1 good_bye_cruel_world()

This will make your script not exist once its done:

    good_bye_cruel_world()

This will replace your script with $note:

    good_bye_cruel_world($note)
   
This will make your script not exist once its done and put $note in [$0 w/out .\w+].ext

    good_bye_cruel_world('.ext', $note)

=head1 When this would actually be handy.

Beleive it or not this is handy if you have a one time job to execute:

    # $script uses Acme::Scripticide
    system $script if -e $script;

or say to create static files from a database:

    # in flowers.pl (copy this to whatever names you want and execute:)
    use Acme::Scripticide qw(good_bye_cruel_world);
    good_bye_cruel_world('.html', get_html($0));

now flowers.pl does not exist and flowers.html is there

You could have a directory full of those types of scripts and glob() them in and execute each one, once done you have a directory of corresponding static html files...

=head1 Disclaimer

Use at your own risk, this deletes your script so you've been warned :)

Only kill your scripts. If you feel like hurting yourself, please seek professional help.

In the interest of not being too morbid I refrained from making aliases to the function with more graphic names.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
