# -*-perl-*-
# Creation date: 2003-10-30 23:04:19
# Authors: Don
# Change log:
# $Id: File.pm,v 1.4 2004/02/01 09:43:42 don Exp $

use strict;

{   package Class::Config::File;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my ($proto, $file_path, $params) = @_;
        my $self = bless {}, ref($proto) || $proto;
        $self->setFilePath($file_path);
        $params = {} unless ref($params) eq 'HASH';
        $self->setParams($params);
        return $self;
    }

    sub slurpFile {
        my ($self, $file_path) = @_;
        local(*IN);
        open(IN, '<' . $file_path) or return undef;
        my $contents = '';
        my $buf = '';
        $contents .= $buf while read(IN, $buf, 1024);
        close IN;
        return $contents;
    }
                    

    sub load {
        my ($self) = @_;
        my $file = $self->getFilePath;
        my $params = $self->getParams;
        my $name_space = $$params{name_space};
        local($SIG{__DIE__});
        # my $file_content = $self->slurpFile($file);
        $name_space = 'Class::Config::File::Temp' if $name_space eq '';
        my $to_eval = qq{package $name_space; use vars qw(\$info);\n};
        $to_eval .= qq{do "$file"; die "do failed on $file: \$\@" if \$\@;};
        eval $to_eval;

        if ($@) {
            # FIXME: need to figure out what to do here
            # print "do failed: $@\n";
            return undef;
        }

        my $info_var = "${name_space}::info";
        no strict 'refs';
        my $info = ${"$info_var"};
        $self->setConfigHash($info);

        
    }

    sub exportMethodsToPackage {
        my ($self, $package, $filters) = @_;

        if (defined($filters) and ref($filters) ne 'ARRAY') {
            $filters = [ $filters ];
        }

        $package = ref($package) if ref($package);
        
        my $info = $self->getConfigHash;
        no strict 'refs';
        while (my ($field, $value) = each %$info) {
            my $meth_name = $self->convertFieldToMethodName($field);

            # create an anonymous subroutine to do the work, then give it a name
            my $meth;
            if ($filters) {
                # apply filters
                $meth = sub {
                    my $val = $value;
                    foreach my $filter (@$filters) {
                        if (ref($filter) eq 'ARRAY') {
                            my ($obj, $func, @args) = @$filter;
                            if (ref($obj) eq 'CODE') {
                                # subroutine reference
                                my @new_args = @$filter;
                                shift @new_args;
                                $val = $obj->($val, @new_args);
                            } else {
                                $val = $obj->$func($val, @args);
                            }
                        } else {
                            $val = $filter->($val);
                        }
                    }
                    return $val;
                }
            } else {
                $meth = sub { return $value };
            }
            *{"$package\:\:$meth_name"} = $meth;
        }
        
        return 1;
    }

    sub convertFieldToMethodName {
        my ($self, $field) = @_;
        my $meth_name = ucfirst($field);
        $meth_name =~ s/_(.)/\U$1/g;
        $meth_name = 'get' . $meth_name;
        
        return $meth_name;
    }

    sub interpolate {
        my ($self, $value) = @_;
        return $value;
    }

    #####################
    # getters and setters

    sub getParams {
        my ($self) = @_;
        return $$self{_params};
    }

    sub setParams {
        my ($self, $params) = @_;
        $$self{_params} = $params;
    }

    sub getConfigHash {
        my ($self) = @_;
        return $$self{_config_hash};
    }

    sub setConfigHash {
        my ($self, $config) = @_;
        $$self{_config_hash} = $config;
    }
    
    sub getFilePath {
        my ($self) = @_;
        return $$self{_file};
    }
    
    sub setFilePath {
        my ($self, $file) = @_;
        $$self{_file} = $file;
    }

}

1;

__END__

=pod

=head1 NAME

 Class::Config::File - Container for a configuration file.

=head1 SYNOPSIS

 This module is not meant to be used directly.  Please use
 Class::Config instead.

=head1 DESCRIPTION


=head1 METHODS


=head1 EXAMPLES


=head1 BUGS


=head1 AUTHOR


=head1 VERSION

$Id: File.pm,v 1.4 2004/02/01 09:43:42 don Exp $

=cut
