package DBIx::POS::Template;
use strict;
use warnings;
use base qw{Pod::Parser};
use Hash::Merge qw(merge);
use Encode;

our $VERSION = '0.067';

# Hold data for our pending statement
my $info = {};
# SQL parse statements
my %sql = ();
# What command we're looking at
my $cmd;
# PODs enc
my $enc; 

# Text::Template->new(%TT, %tt)
our %TT = (
    DELIMITERS => ['{%', '%}'],
    #~ BROKEN => sub { die @_;},
);

my %tt = (); # instance scope: Text::Template->new(..., tt=>{%TT, %tt}, )
my $tt = {}; # new scope: Text::Template->new(..., tt=>{%TT, %$tt}, )
my %template = (); # instance scope: Text::Template->new(..., template=>\%template, )
my $template = {}; # new scope: Text::Template->new(..., template=>$template, )
my $scope; # 'new' | 'instance'

our %CACHE = ();

# separate object
sub new {
    my ($class, $file, %arg) = @_;
    # change file
    $file = _file( $file,);
    
    return $CACHE{$file} # если был синглетон, то заново распарсить файл
        if exists $CACHE{$file} && ref $CACHE{$file};
    
    $scope = 'new';
    
    $tt = $arg{TT} || $arg{tt} || {};
    $template = $arg{template} || {};
    
    
    $class->_process( $file,);
    
    my $new = { %sql };
    %sql = ();

    $CACHE{$file} = bless $new, $class;
}

# class singleton
my $instance;
sub singleton { shift->instance(@_) }
sub instance {
    my ($class, $file, %arg) = @_;
    $instance ||= bless({}, ref($class) || $class);
    
    $file = _file( $file,);# change file
    
    if (exists $CACHE{$file}) {# кэш для синглетона просто число, если этот файл был new, то в кэше объект и его записи перенести в синглетон
        return $instance
            unless ref $CACHE{$file};
        
        @$instance{ keys %{$CACHE{$file}} } = values %{$CACHE{$file}};
        
        return $instance;
    }
    
    $scope = 'instance';
    # merge prev tt opts
    my $tt = $arg{TT} || $arg{tt};
    @tt{ keys %$tt } = values %$tt
        if $tt;
    #~ @template{ keys %{$arg{template}} } = values %{$arg{template}} хэш сложный!
   
    %template = %{merge($arg{template}, \%template)}
        if $arg{template} && %{$arg{template}};
    
    $class->_process( $file,);
    
    $CACHE{$file}++;
    
    @$instance{ keys %sql } = values %sql;
    %sql = ();
    $instance;
}

sub _process {# pos file/module
    my ($class, $file,) = @_;
    #~ return unless $file;
    #~ warn "Processing file [$file]";
    $enc = undef;
    $class->SUPER::new->parse_from_file($file);
}

sub _file {
    my ($file,) = @_;
    #~ return unless $file;
    $file .='.pm'
        if $file =~ s/::/\//g;
    $file = $INC{$file}
        unless -e $file;
    die "No such file [$file]"
        unless -e $file;
    return $file;
}

sub template {
    my ($self, $key, %arg) = @_;
    die "No such item by key [$key] on this POS, please check processed file(s)"
        unless $self->{$key};
    $self->{$key}->template(%arg);
}

########### Parser ################

# Handle =whatever commands
sub command {
    my ($self, $command, $paragraph, $line) = @_;

    # Get rid of all trailing whitespace
    $paragraph =~ s/\s+$//ms;

    # There may be a short description right after the command
    if ($command eq 'desc') {
        $info->{desc} = $paragraph || "";
    }

    # The name comes right after the command
    if ($command eq 'name') {
        $self->end_input;
        $info->{name} = $paragraph;
    }

    # The noreturn comes right after the command
    if ($command eq 'noreturn') {
        $info->{noreturn} = 1;
    }
    
    if ($command eq 'encoding') {
        $enc = $paragraph;
    }

    # Remember what command we're in
    $cmd = $command;
}

sub end_input {
    my ($self) = @_;
    # If there's stuff to try and construct from
    if (%{$info}) {
        # If we have the necessary bits
        #~ if (scalar (grep {m/^(?:name|short|desc|sql)$/} keys %{$info}) == 3) {
        if (defined($info->{name}) && defined($info->{sql})) {
            # Grab the entire content for the %sql hash
            if ($enc) {
                my @enc = qw(name desc param short sql);
                @$info{ @enc } = map Encode::decode($enc, $info->{$_}), @enc;
            }
            $sql{$info->{name}} = DBIx::POS::Statement->new (
                $info,
                tt => {%TT, $scope eq 'new' ? %$tt : %tt},
                template => $scope eq 'new' ? $template : \%template,
                #~ enc=>$enc,
            );
            # Start with a new empty hashref
            $info = {};
        } else {# Something's missing
            warn "Malformed entry: ", %$info;# . Dump (\%sql, $info);
        }
    }
}


# Handle the blocks of text between commands
sub textblock {
    my ($parser, $paragraph, $line) = @_;

    # Collapse trailing whitespace to a \n
    $paragraph =~ s/\s+$/\n/ms;

    if ($cmd eq 'desc') {
        $info->{desc} .= $paragraph;
    }

    elsif ($cmd eq 'param') {
        $info->{param} .= $paragraph;
    }

    elsif ($cmd eq 'sql') {
        $info->{sql} .= $paragraph;
    }
}

# We handle verbatim sections the same way
sub verbatim {
    my ($parser, $paragraph, $line) = @_;

    # Collapse trailing whitespace to a \n
    $paragraph =~ s/\s+$/\n/ms;

    if ($cmd eq 'desc') {
        $info->{desc} .= $paragraph;
    }

    elsif ($cmd eq 'param') {
        $info->{param} .= $paragraph;
    }

    elsif ($cmd eq 'sql') {
        $info->{sql} .= $paragraph;
    }
}

1;
#=============================================
package DBIx::POS::Statement;
#=============================================
use Text::Template;
use Hash::Merge qw(merge);


use overload '""' => sub { shift->template };

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = shift;
    my %arg = @_;
    $self->{_TT} = $arg{TT} || $arg{tt} ;
    $self->{_template_default} = $arg{template};

    bless ($self, $class);
    $self->_eval_param();
    return $self;
}

sub desc {
    my $self = shift;
    $self->{desc} = shift if (@_);
    return $self->{desc};
}

sub name {
    my $self = shift;
    $self->{name} = shift if (@_);
    return $self->{name};
}

sub noreturn {
    my $self = shift;
    $self->{noreturn} = shift if (@_);
    return $self->{noreturn};
}

sub param {# ->param() |  ->param('foo') | ->param('foo'=>'bar', ....)
    my $self = shift;
    return unless defined $self->{param};
    #~ $self->{param} ||= {};
    return $self->{param} unless ref $self->{param} eq 'HASH';
    return $self->{param} unless @_;
    return $self->{param}{ shift() } if @_ == 1;
    my %arg = @_;
    @{$self->{param} ||= {}}{ keys %arg } = values %arg;
}

sub _eval_param {
    my $self = shift;
    return unless $self->{param};
    my $param = eval $self->{param};
    die "Malformed perl code param [$self->{param}]: $@" if $@;
    $self->{param} = $param;
}


sub short {
    my $self = shift;
    $self->{short} = shift if (@_);
    return $self->{short};
}

sub sql {
    my $self = shift;
    $self->{sql} = shift if (@_);
    return $self->{sql};
}

sub template {
    my ($self, %arg) = @_;
    #~ return $self->{sql}
        #~ unless scalar(%arg) || scalar(%{$self->{_template_default}});
    $self->{_template} ||= Text::Template->new(
        TYPE => 'STRING',
        SOURCE => $self->sql,
        %{$self->{_TT}},
    );
    #~ $self->{_template}->fill_in(HASH=>{%{$self->{_template_default}}, %arg},);#BROKEN_ARG=>\'error!', BROKEN => sub { die @_;},
    #~ return $self->{_template}->fill_in(HASH=>$self->{_template_default})
        #~ unless %arg;
    #~ return $self->{_template}->fill_in(HASH=>\%arg)
        #~ unless %{$self->{_template_default}};
    $self->{_template}->fill_in(HASH=>#merge(\%arg, $self->{_template_default}));
        %arg ? %{$self->{_template_default}} ? merge(\%arg, $self->{_template_default}) : \%arg : $self->{_template_default}
    );
}


=pod

=encoding utf8

=head1 DBIx::POS::Template

Доброго всем

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 VERSION

0.067

=head1 NAME

DBIx::POS::Template - is a fork of L<DBIx::POS>. Define a dictionary of SQL statements in a POD dialect (POS) plus expand template sql with embedded Perl using L<Text::Template>.

=head1 SYNOPSIS

  use DBIx::POS::Template;

  # separate object
  my $pos = DBIx::POS::Template->new(__FILE__, ...);
  # or singleton DBIx::POS::Template->instance($file, ...);
  
  my $sql = $pos->{test1}->template(where => "bar = ?");
  # or $pos->template('test1', where => "bar = ?")
  
  =pod

  =name test1

  =desc test the DBIx::POS::Template module

  =param
  
    # Some arbitrary parameters as perl code (eval)
    {
        cache=>1, # will be prepare_cached
    }

  =sql

    select * from foo
    {% $where %}
    ;

  =cut

Or:

  package POS::Foo;
  use DBIx::POS::Template;
  use Hash::Merge qw(merge);
  
  my $default = {foo=>'bar',};
  
  sub new {
    my $proto = shift;
    DBIx::POS::Template->new(__FILE__, template => merge({@_}, $default));
    # or DBIx::POS::Template->instance(...
  }

=head1 DESCRIPTION

DBIx::POS::Template is subclass Pod::Parser to define a POD dialect for writing a SQL dictionary(s) with templating.

By separating the SQL code from its normal context of execution, it
encourages you to do other things with it---for instance, it is easy
to create a script that can do performance testing of certain SQL
statements in isolation, or to create generic command-line wrapper
around your SQL statements.

By giving a framework for documenting the SQL, it encourages
documentation of the intent and/or implementation of the SQL code.  It
also provides all of that information in a format from which other
documentation could be generated---say, a chunk of DocBook for
incorporation into a guide to programming the application.

This class whould work as separate objects per pod-file or as singleton for all processed files with one dictionary of them.

=head1 METHODS

=head2 new($file, <options>)

Create separate object and process $file POS with options names:

=over 4

=item * TT | tt

Optional hashref will passing to L<Text::Template>->new() for each parsed statement. By default only defined the key:

  ..., TT => {DELIMITERS => ['{%', '%}'],},

For B<instance> this hashref will be merged with previous instance invokes.

=item * template

  ..., template => {foo=>1,},

Optional hashref of default values for each statement template. For B<instance> this hashref will be merged with previous instance invokes.

=back

=head2 instance($file, <options>)

Return singleton dictionary object, parsed $file keys will collapse/override with previous instances files. Same options as C<new>. B<tt> and B<template> options merge with previous options of instance invokes.

=head2 template($key, var1 => ..., var2 => ...)

Fill in dictionary sql with variables by L<Text::Template#HASH>. Other syntax:

    $pos->{$key}->template(var1 => ..., var2 => ...)

=head1 SEE ALSO

L<Pod::Parser>

L<DBIx::POS>

L<Text::Template>

L<DBIx::POS::Sth>

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/DBIx-POS-Template/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2016 Mikhail Che.

This module is free software; you can redistribute it and/or modify it under the term of the Perl itself.

=cut
