package CGI::Kwiki::Config;
$VERSION = '0.14';
use strict;
use CGI::Kwiki;

attribute "${_}_class"
  for CGI::Kwiki::classes();
attribute 'top_page';
attribute 'driver';
attribute 'encoding';
attribute 'page_language';

sub all {
    my ($self) = @_;
    return %$self;
}

sub new {
    my ($class) = @_;
    my ($config_file, @error) = 
      grep {not /(~|\.bak)$/} glob "config.*";
    if (not defined $config_file) {
        my $self = bless {}, $class;
        $self->set_defaults;
        return $self;
    }
    die "More than one config file found"
      if @error;
    die "Invalid config file name '$config_file'"
      unless $config_file =~ /config\.(\w+)/;
    my $extension = lc($1);
    my $parse_class = "CGI::Kwiki::Config_$extension";
    eval qq{ require $parse_class }; die $@ if $@;
    my $parser = $parse_class->new;
    my $hash = $parser->parse_file($config_file);
    my $config_class = $hash->{config_class}
      or die "config_class not defined in $config_file\n";
    eval qq{ require $config_class }; die $@ if $@;
    my $self = bless $hash, $config_class;
    attribute($_) for grep { not /_class$/ and
        $_ ne 'top_page'
    } keys %$hash;
    $self->set_defaults;

    if ($self->encoding and $self->encoding =~ /\bauto\b/i) {
	$self->{encoding} = (($] >= 5.008) ? 'UTF-8' : 'ISO-8859-1');
    }

    if ($self->page_language and $self->page_language =~ /\bauto\b/i and
	$self->encoding =~ /\butf-?8\b/i and $] >= 5.008
    ) {
	eval "use " . $self->i18n_class;
	for (grep /^\w+_page$/, keys %$self) {
	    $self->{"loc_$_"} = $self->i18n_class->loc($self->{$_});
	}
    }
    else {
	$self->{"loc_$_"} ||= $self->{$_} for grep /^\w+page$/, keys %$self;
    }

    return $self;
}

sub set_defaults {
    my ($self) = @_;
    for my $class (CGI::Kwiki::classes()) {
        my $Class = $class;
        $Class =~ s/(.)/uc($1)/e;
        $Class = uc($class) if $class eq 'cgi';
        $class = "${class}_class";
        $self->$class("CGI::Kwiki::$Class")
          if not defined $self->{$class};
    }
}

1;

__END__

=head1 NAME 

CGI::Kwiki::Config - Config Base Class for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
