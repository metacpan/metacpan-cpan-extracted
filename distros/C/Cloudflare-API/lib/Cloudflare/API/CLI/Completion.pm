#
#  This file is part of Cloudflare::API.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#
#  Render self-contained shell completion for cloudflare-api
#
package Cloudflare::API::CLI::Completion;


#  Compiler pragmas
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;


#  Version information
#
$VERSION='1.010';


#============================================================================


sub generate {


    #  Check the requested shell and command specification
    #
    my ($shell, $spec_hr)=@_;
    die "completion shell is required; valid shells: bash, fish, zsh\n"
        unless defined($shell)&&length($shell);
    die "unknown completion shell '$shell'; valid shells: bash, fish, zsh\n"
        unless $shell=~/\A(?:bash|fish|zsh)\z/;
    die "completion specification must be a hash reference\n"
        unless ref($spec_hr) eq 'HASH';
    die "completion resources must be a hash reference\n"
        unless ref($spec_hr->{'resources'}) eq 'HASH';
    die "completion options must be an array reference\n"
        unless ref($spec_hr->{'options'}) eq 'ARRAY';


    #  Render the selected shell without consulting external state
    #
    return bash($spec_hr) if $shell eq 'bash';
    return fish($spec_hr) if $shell eq 'fish';
    return zsh($spec_hr);

}


sub bash {

    my $spec_hr=shift();
    my @resource=sort(keys(%{$spec_hr->{'resources'}}));
    my @action=all_actions($spec_hr);
    my @option=map { $_->[0] } @{$spec_hr->{'options'}};
    my $resource=join(' ', @resource);
    my $action=join(' ', @action);
    my $option=join(' ', @option);
    my $output=<<'BASH';
# bash completion for cloudflare-api
_cloudflare_api_actions()
{
    case "$1" in
BASH
    foreach my $name (@resource) {
        my @name_action=sort(keys(%{$spec_hr->{'resources'}{$name}}));
        $output.='        '.shell_quote($name).') printf \'%s\\n\'';
        $output.=' '.join(' ', map { shell_quote($_) } @name_action)." ;;\n";
    }
    $output.=<<'BASH';
    esac
}

_cloudflare_api_option_kind()
{
    case "$1" in
BASH
    foreach my $option_ar (@{$spec_hr->{'options'}}) {
        $output.='        '.shell_quote($option_ar->[0]).') printf \'%s\' '.
            shell_quote($option_ar->[1])." ;;\n";
    }
    $output.=<<'BASH';
        *) printf '%s' flag ;;
    esac
}

_cloudflare_api_complete()
{
    local cur resource action expect word kind candidate option_value value i
    local resources actions options
    COMPREPLY=()
BASH
    $output.="    resources=".shell_quote($resource)."\n";
    $output.="    actions=".shell_quote($action)."\n";
    $output.="    options=".shell_quote($option)."\n";
    $output.=<<'BASH';
    cur=${COMP_WORDS[COMP_CWORD]}

    for ((i=1; i<COMP_CWORD; i++)); do
        word=${COMP_WORDS[i]}
        if [[ -n $expect ]]; then
            [[ $expect == resource ]] && resource=$word
            [[ $expect == action ]] && action=$word
            expect=
            continue
        fi
        case "$word" in
            --resource=*) resource=${word#*=} ;;
            --action=*) action=${word#*=} ;;
            --*=*) ;;
            -*)
                kind=$(_cloudflare_api_option_kind "$word")
                [[ $kind != flag ]] && expect=$kind
                ;;
            *)
                if [[ -z $resource ]]; then
                    resource=$word
                elif [[ -z $action ]]; then
                    action=$word
                fi
                ;;
        esac
    done

    if [[ -n $expect ]]; then
        case "$expect" in
            resource) COMPREPLY=( $(compgen -W "$resources" -- "$cur") ) ;;
            action)
                candidate=$(_cloudflare_api_actions "$resource")
                [[ -z $candidate ]] && candidate=$actions
                COMPREPLY=( $(compgen -W "$candidate" -- "$cur") )
                ;;
            auth) COMPREPLY=( $(compgen -W 'wrangler' -- "$cur") ) ;;
            output) COMPREPLY=( $(compgen -W 'json dumper' -- "$cur") ) ;;
            shell) COMPREPLY=( $(compgen -W 'bash fish zsh' -- "$cur") ) ;;
            method) COMPREPLY=( $(compgen -W 'DELETE GET PATCH POST PUT' -- "$cur") ) ;;
            bool) COMPREPLY=( $(compgen -W 'false true' -- "$cur") ) ;;
            file)
                while IFS= read -r candidate; do
                    COMPREPLY[${#COMPREPLY[@]}]=$candidate
                done < <(compgen -f -- "$cur")
                ;;
        esac
        return
    fi

    if [[ $cur == --*=* ]]; then
        option_value=${cur%%=*}
        value=${cur#*=}
        kind=$(_cloudflare_api_option_kind "$option_value")
        case "$kind" in
            resource) candidate=$resources ;;
            action)
                candidate=$(_cloudflare_api_actions "$resource")
                [[ -z $candidate ]] && candidate=$actions
                ;;
            auth) candidate=wrangler ;;
            output) candidate='json dumper' ;;
            shell) candidate='bash fish zsh' ;;
            method) candidate='DELETE GET PATCH POST PUT' ;;
            bool) candidate='false true' ;;
            file)
                while IFS= read -r candidate; do
                    COMPREPLY[${#COMPREPLY[@]}]="${option_value}=${candidate}"
                done < <(compgen -f -- "$value")
                return
                ;;
            *) return ;;
        esac
        for candidate in $(compgen -W "$candidate" -- "$value"); do
            COMPREPLY[${#COMPREPLY[@]}]="${option_value}=${candidate}"
        done
        return
    fi

    if [[ $cur == -* ]]; then
        COMPREPLY=( $(compgen -W "$options" -- "$cur") )
    elif [[ -z $resource ]]; then
        COMPREPLY=( $(compgen -W "$resources" -- "$cur") )
    elif [[ -z $action ]]; then
        candidate=$(_cloudflare_api_actions "$resource")
        COMPREPLY=( $(compgen -W "$candidate" -- "$cur") )
    fi
}

complete -F _cloudflare_api_complete cloudflare-api
BASH
    return $output;

}


sub zsh {

    my $spec_hr=shift();
    my @resource=sort(keys(%{$spec_hr->{'resources'}}));
    my @action=all_actions($spec_hr);
    my @option=map { $_->[0] } @{$spec_hr->{'options'}};
    my $resource=join(' ', @resource);
    my $action=join(' ', @action);
    my $option=join(' ', @option);
    my $output=<<'ZSH';
#compdef cloudflare-api

_cloudflare_api_actions()
{
    case "$1" in
ZSH
    foreach my $name (@resource) {
        my @name_action=sort(keys(%{$spec_hr->{'resources'}{$name}}));
        $output.='        '.shell_quote($name).') print -l -- ';
        $output.=join(' ', map { shell_quote($_) } @name_action)." ;;\n";
    }
    $output.=<<'ZSH';
    esac
}

_cloudflare_api_option_kind()
{
    case "$1" in
ZSH
    foreach my $option_ar (@{$spec_hr->{'options'}}) {
        $output.='        '.shell_quote($option_ar->[0]).') print -rn -- '.
            shell_quote($option_ar->[1])." ;;\n";
    }
    $output.=<<'ZSH';
        *) print -rn -- flag ;;
    esac
}

_cloudflare_api()
{
    local cur resource action expect word kind option_value value candidate
    local -a resources actions options candidates
    integer i
ZSH
    $output.="    resources=(".join(' ', map { shell_quote($_) } @resource).")\n";
    $output.="    actions=(".join(' ', map { shell_quote($_) } @action).")\n";
    $output.="    options=(".join(' ', map { shell_quote($_) } @option).")\n";
    $output.=<<'ZSH';
    cur=$words[$CURRENT]

    for ((i=2; i<CURRENT; i++)); do
        word=$words[$i]
        if [[ -n $expect ]]; then
            [[ $expect == resource ]] && resource=$word
            [[ $expect == action ]] && action=$word
            expect=
            continue
        fi
        case "$word" in
            --resource=*) resource=${word#*=} ;;
            --action=*) action=${word#*=} ;;
            --*=*) ;;
            -*)
                kind=$(_cloudflare_api_option_kind "$word")
                [[ $kind != flag ]] && expect=$kind
                ;;
            *)
                if [[ -z $resource ]]; then
                    resource=$word
                elif [[ -z $action ]]; then
                    action=$word
                fi
                ;;
        esac
    done

    if [[ -n $expect ]]; then
        case "$expect" in
            resource) compadd -- $resources ;;
            action)
                candidates=( ${(f)"$(_cloudflare_api_actions "$resource")"} )
                (( ${#candidates} )) || candidates=( $actions )
                compadd -- $candidates
                ;;
            auth) compadd -- wrangler ;;
            output) compadd -- json dumper ;;
            shell) compadd -- bash fish zsh ;;
            method) compadd -- DELETE GET PATCH POST PUT ;;
            bool) compadd -- false true ;;
            file) _files ;;
        esac
        return
    fi

    if [[ $cur == --*=* ]]; then
        option_value=${cur%%=*}
        value=${cur#*=}
        kind=$(_cloudflare_api_option_kind "$option_value")
        case "$kind" in
            resource) candidates=( $resources ) ;;
            action)
                candidates=( ${(f)"$(_cloudflare_api_actions "$resource")"} )
                (( ${#candidates} )) || candidates=( $actions )
                ;;
            auth) candidates=( wrangler ) ;;
            output) candidates=( json dumper ) ;;
            shell) candidates=( bash fish zsh ) ;;
            method) candidates=( DELETE GET PATCH POST PUT ) ;;
            bool) candidates=( false true ) ;;
            *) return ;;
        esac
        candidates=( ${^candidates/#/${option_value}=} )
        compadd -- $candidates
        return
    fi

    if [[ $cur == -* ]]; then
        compadd -- $options
    elif [[ -z $resource ]]; then
        compadd -- $resources
    elif [[ -z $action ]]; then
        candidates=( ${(f)"$(_cloudflare_api_actions "$resource")"} )
        compadd -- $candidates
    fi
}

compdef _cloudflare_api cloudflare-api
ZSH
    return $output;

}


sub fish {

    my $spec_hr=shift();
    my @resource=sort(keys(%{$spec_hr->{'resources'}}));
    my @action=all_actions($spec_hr);
    my $resource=join(' ', @resource);
    my $action=join(' ', @action);
    my $output=<<'FISH';
# fish completion for cloudflare-api
function __cloudflare_api_seen
    set -l words (commandline -opc)
    for word in $words
        set word (string replace -r '^--resource=' '' -- $word)
        set word (string replace -r '^--action=' '' -- $word)
        contains -- $word $argv; and return 0
    end
    return 1
end

complete -c cloudflare-api -f
FISH
    $output.='complete -c cloudflare-api -n '.
        shell_quote("not __cloudflare_api_seen $resource").' -a '.
        shell_quote($resource).' -d '.shell_quote('resource')."\n";
    foreach my $name (@resource) {
        my @name_action=sort(keys(%{$spec_hr->{'resources'}{$name}}));
        my $name_action=join(' ', @name_action);
        my $condition="__cloudflare_api_seen $name; and not __cloudflare_api_seen $action";
        $output.='complete -c cloudflare-api -n '.shell_quote($condition).' -a '.
            shell_quote($name_action).' -d '.shell_quote("$name action")."\n";
    }
    foreach my $option_ar (@{$spec_hr->{'options'}}) {
        my ($name, $kind, $description)=@$option_ar;
        my $switch=$name=~/\A--(.+)\z/ ? '-l '.shell_quote($1) :
            $name=~/\A-(.)\z/ ? '-s '.shell_quote($1) : next;
        my $line='complete -c cloudflare-api '.$switch;
        $line.=' -d '.shell_quote($description) if defined($description);
        if ($kind eq 'resource') {
            $line.=' -r -f -a '.shell_quote($resource);
        }
        elsif ($kind eq 'action') {
            foreach my $resource_name (@resource) {
                my $actions=join(' ', sort(keys(%{$spec_hr->{'resources'}{$resource_name}})));
                $output.=$line.' -r -f -n '.shell_quote("__cloudflare_api_seen $resource_name").
                    ' -a '.shell_quote($actions)."\n";
            }
            next;
        }
        elsif ($kind eq 'auth') {
            $line.=' -r -f -a '.shell_quote('wrangler');
        }
        elsif ($kind eq 'output') {
            $line.=' -r -f -a '.shell_quote('json dumper');
        }
        elsif ($kind eq 'shell') {
            $line.=' -r -f -a '.shell_quote('bash fish zsh');
        }
        elsif ($kind eq 'method') {
            $line.=' -r -f -a '.shell_quote('DELETE GET PATCH POST PUT');
        }
        elsif ($kind eq 'bool') {
            $line.=' -r -f -a '.shell_quote('false true');
        }
        elsif ($kind eq 'file') {
            $line.=' -r -F';
        }
        elsif ($kind ne 'flag') {
            $line.=' -r -f';
        }
        $output.=$line."\n";
    }
    return $output;

}


sub all_actions {

    my $spec_hr=shift();
    my %action;
    foreach my $resource (keys(%{$spec_hr->{'resources'}})) {
        @action{keys(%{$spec_hr->{'resources'}{$resource}})}=();
    }
    return sort(keys(%action));

}


sub shell_quote {

    my $value=shift();
    $value=~s/'/'"'"'/g;
    return "'$value'";

}


1;
__END__

=begin markdown

# Cloudflare::API::CLI::Completion #

# NAME #

Cloudflare::API::CLI::Completion - render offline shell completion for cloudflare-api

# SYNOPSIS #

```perl
require Cloudflare::API::CLI::Completion;
my $script=Cloudflare::API::CLI::Completion::generate($shell, $spec_hr);
```

# DESCRIPTION #

`Cloudflare::API::CLI::Completion` renders self-contained Bash, Zsh, and Fish completion scripts from the command specification supplied by `cloudflare-api`. It performs no authentication, network access, or Cloudflare resource discovery.

# FUNCTIONS #

## generate($shell, $spec_hr) ##

Return the completion script for `bash`, `zsh`, or `fish`. The specification must contain a `resources` hash and an `options` array. An unsupported shell or malformed specification throws an exception.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Cloudflare::API.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Cloudflare::API::CLI::Completion - render offline shell completion for cloudflare-api


=head1 SYNOPSIS


 require Cloudflare::API::CLI::Completion;
 my $script=Cloudflare::API::CLI::Completion::generate($shell, $spec_hr);

=head1 DESCRIPTION

C<Cloudflare::API::CLI::Completion> renders self-contained Bash, Zsh, and Fish completion scripts from the command specification supplied by C<cloudflare-api>. It performs no authentication, network access, or Cloudflare resource discovery.


=head1 FUNCTIONS


=head2 generate($shell, $spec_hr)

Return the completion script for C<bash>, C<zsh>, or C<fish>. The specification must contain a C<resources> hash and an C<options> array. An unsupported shell or malformed specification throws an exception.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
