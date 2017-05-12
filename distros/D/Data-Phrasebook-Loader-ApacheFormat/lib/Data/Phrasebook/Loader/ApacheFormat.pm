package Data::Phrasebook::Loader::ApacheFormat;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

use Config::ApacheFormat;
use Carp qw(croak);
use base qw( Data::Phrasebook::Loader::Base Data::Phrasebook::Debug );

sub load {
    my ($self, $file, $dict) = @_;
    croak "Missing required file option." 
      unless defined $file;
    croak "Specified file '$file' cannot be read."
      unless -r $file;

    # load the file, looking in the cache first.  Caching is a
    # necessity here because Data::Phrasebook reloads every time
    # dict() is changed, which, for my use, is very common
    our %CACHE;
    my $mtime = (stat($file))[9];
    if ($CACHE{$file} and $CACHE{$file}{mtime} == $mtime) {
        # fetch from the cache
        $self->{conf} = $CACHE{$file}{conf};

    } else {
        # load a new file
        $self->{conf} = Config::ApacheFormat->new();
        $self->{conf}->read($file);
        $CACHE{$file}{conf}  = $self->{conf};
        $CACHE{$file}{mtime} = $mtime;
    }

    # store dict for use in get

    $self->{dict} = $dict;
}

sub get {
    my ($self, $key) = @_;
    my $conf = $self->{conf};
    my $dict = $self->{dict};    

    # look in dict block if set and available in the file
    if ($dict and my $block = eval { $conf->block($dict) }) {
        $conf = $block;
    }

    return $conf->get($key);
}

1;

__END__

=head1 NAME

Data::Phrasebook::Loader::ApacheFormat - Config::ApacheFormat phrasebook loader

=head1 SYNOPSIS

  use Data::Phrasebook;

  # load a phrasebook using Config::ApacheFormat syntax
  $book = Data::Phrasebook->new(class  => 'Plain',
                                loader => 'ApacheFormat',
                                file   => 'phrases.conf');

  # lookup some values, with optional value replacement
  $data = $book->fetch('key');
  $data = $book->fetch('key2', { name => 'value'});

  # switch dictionaries (blocks in the configuration file)
  $book->dict('NewDict');

  # get value for key in the NewDict block
  $data = $book->fetch('key');

And your configuration file ('phrases.conf' in the code above) looks
like:

  key "Some ol' value"
  key2 100.00

  <NewDict>
    key "A special value for NewDict"
  </NewDict>

=head1 DESCRIPTION

This module allows you to use
L<Config::ApacheFormat|Config::ApacheFormat> with
L<Data::Phrasebook|Data::Phrasebook>.  It should function just like
any other Data::Phrasebook backend.

=head1 BUGS

I know of no bugs in this module.  If you find one, please file a bug
report at:

  http://rt.cpan.org

Alternately you can email me directly at sam@tregar.com.  Please
include the version of the module and a complete test case that
demonstrates the bug.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

Thanks to Plus Three, LP (http://plusthree.com) for sponsoring my work
on this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Sam Tregar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
