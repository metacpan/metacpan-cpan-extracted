package App::orgadb;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::orgadb::Common;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-19'; # DATE
our $DIST = 'App-orgadb'; # DIST
our $VERSION = '0.020'; # VERSION

our %SPEC;

our %FEATURES = (
    set_v => {PasswordManager => 1},
    features => {
        PasswordManager => {
            can_add_password                         => 0,
            can_add_note                             => 0,
            can_add_custom_fields                    => 0,

            can_edit_password                        => 0,
            can_record_edit_history                  => 0,

            can_delete_password                      => 0,

            can_retrieve_password                    => 1,
            can_dump_passwords                       => 1,

            can_encrypt_password                     => 1,
            can_encrypt_label                        => 1,
            can_encrypt_other_fields                 => 1,

            database_format                          => 'Org',
            database_format_is_open_standard         => 1,
            encryption_format                        => 'OpenPGP',
            encryption_format_is_open_standard       => 1,
        },
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'An opinionated Org addressbook toolset',
};

sub _highlight {
    my ($clrtheme_obj, $re, $text) = @_;
    return $text unless $clrtheme_obj && $re;

    require ColorThemeUtil::ANSI;
    my $ansi_highlight = ColorThemeUtil::ANSI::item_color_to_ansi($clrtheme_obj->get_item_color('highlight'));
    $text =~ s/($re)/$ansi_highlight$1\e[0m/g;
    $text;
}

# this is like select(), but selects from object trees instead of from an Org
# file.
sub _select_single {
    my %args = @_;

    #print "$_ => $args{$_}\n" for sort keys %args;

    my $trees = $args{_trees};
    my $tree_filenames = $args{_tree_filenames};

    my $res = [200, "OK", ""];
    my @outputted_field_values;

    my @parsed_field_value_formatter_rules;

    my $field_value_formatter_from_args;
    my $field_value_formatter_filters_from_args;
  SET_FIELD_VALUE_FORMATTERS_FROM_ARGS:
    {
        last if $args{no_field_value_formatters};
        last unless $args{field_value_formatters} && @{ $args{field_value_formatters} };
        my @filter_names;
        for my $f (@{ $args{field_value_formatters} }) {
            if ($f =~ /\A\[/) {
                require JSON::PP;
                $f = JSON::PP::decode_json($f);
            } else {
                if ($f =~ /(.+)=(.*)/) {
                    my ($modname, $args) = ($1, $2);
                    # normalize / to :: in the module name part
                    $modname =~ s!/!::!g;
                    $f = [$modname, { split /,/, $args }];
                } else {
                    # normalize / to ::
                    $f =~ s!/!::!g;
                }
            }
            push @filter_names, $f;
        }
        $field_value_formatter_filters_from_args = \@filter_names;
        require Data::Sah::Filter;
        $field_value_formatter_from_args = Data::Sah::Filter::gen_filter(
            filter_names => \@filter_names,
            return_type => 'str_errmsg+val',
        );
    }

    my @matching_entries;
    my ($re_category, $re_entry, $re_field);
  FIND_ENTRIES: {
        require Data::CSel;
        require Data::Dmp;

        my $expr = '';

        if (defined $args{category}) {
            $expr .= 'Headline[level=1][title.as_string';
            if (ref $args{category} eq 'Regexp') {
                $re_category = $args{category};
            } else {
                $re_category = quotemeta($args{category});
                $re_category = qr/$re_category/i;
            }
            $expr .= " =~ " . Data::Dmp::dmp($re_category) . "]";
        }

        $expr .= (length $expr ? " " : "") . 'Headline[level=2]';
        if (defined $args{entry}) {
            $expr .= '[title.as_string';
            if ($args{entry_match_mode} =~ /exact/) {
                $re_entry = quotemeta($args{entry});
                $re_entry = $args{entry_match_mode} =~ /-ci/ ? qr/^$re_entry$/i : qr/^$re_entry$/;
            } elsif (ref $args{entry} eq 'Regexp') {
                $re_entry = $args{entry};
            } else {
                $re_entry = quotemeta($args{entry});
                $re_entry = qr/$re_entry/i;
            }
            $expr .= " =~ " . Data::Dmp::dmp($re_entry) . "]";
        }

        if (defined($args{filter_entries_by_fields}) && @{ $args{filter_entries_by_fields} }) {
            require Regexp::From::String;
            my $expr_field = '';
            for my $field_term (@{ $args{filter_entries_by_fields} }) {
                my ($field_name, $field_value);
                if ($field_term =~ /(.+?)\s*=\s*(.+)/) {
                    $field_name = Regexp::From::String::str_to_re({case_insensitive=>1}, $1);
                    $field_value = Regexp::From::String::str_to_re({case_insensitive=>1}, $2);
                } else {
                    $field_name = Regexp::From::String::str_to_re({case_insensitive=>1}, $field_term);
                }
                #$expr_field .= ($expr_field ? ' > List > ' : 'Headline[level=2] > List > ');
                $expr_field .= ($expr_field ? ' > List > ' : 'List > ');
                $expr_field .= 'ListItem[desc_term.text =~ '.Data::Dmp::dmp($field_name).']';
                if ($field_value) {
                    $expr_field .= '[children_as_string =~ '.Data::Dmp::dmp($field_value).']';
                }
            }
            $expr .= ":has($expr_field)";
        }

        log_trace "CSel expression for selecting entries: <$expr>";

        for my $tree (@$trees) {
            my @nodes = Data::CSel::csel({
                class_prefixes => ["Org::Element"],
            }, $expr, $tree);
            #use Tree::Dump; for (@nodes) { td $_; print "\n\n\n" }
            push @matching_entries, @nodes;
            if ($args{num_entries} && @matching_entries > $args{num_entries}) {
                splice @matching_entries, $args{num_entries};
                last FIND_ENTRIES;
            }
        }
    } # FIND_ENTRIES
    log_trace "Number of matching entries: %d", scalar(@matching_entries);

    #use Tree::Dump; for (@matching_entries) { td $_; print "\n" }
  DISPLAY_ENTRIES: {
        if ($args{count}) {
            return [200, "OK", scalar(@matching_entries)];
        }

        my ($clrtheme, $clrtheme_obj);
      LOAD_COLOR_THEME: {
            my $color = $args{color} // 'auto';
            my $use_color =
                ($color eq 'always' ? 1 : $color eq 'never' ? 0 : undef) //
                (defined $ENV{NO_COLOR} ? 0 : undef) //
                ($ENV{COLOR} ? 1 : defined($ENV{COLOR}) ? 0 : undef) //
                (-t STDOUT); ## no critic: InputOutput::ProhibitInteractiveTest
            last unless $use_color;
            require Module::Load::Util;
            $clrtheme = $args{color_them} // $ENV{ORGADB_COLOR_THEME} // 'Light';
            $clrtheme_obj = Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefixes=>['ColorTheme::Search','ColorTheme','']}, $clrtheme);
        };

        my ($expr_field, @re_field);
        my $i = -1;
      ENTRY:
        for my $entry (@matching_entries) {
            $i++;

            my @matching_fields;
            if (defined($args{fields}) && @{ $args{fields} }) {
                unless (defined $expr_field) {
                    $expr_field = '';
                    for my $field_term (@{ $args{fields} }) {
                        $expr_field .= ($expr_field ? ' > List > ' : 'Headline[level=2] > List > ');
                        $expr_field .= 'ListItem[desc_term.text';
                        my $re_field;
                        if ($args{field_match_mode} =~ /exact/) {
                            $re_field = quotemeta($field_term);
                            $re_field = $args{field_match_mode} =~ /-ci/ ? qr/^$re_field$/i : qr/^$re_field$/;
                        } elsif (ref $field_term eq 'Regexp') {
                            $re_field = $field_term;
                        } else {
                            $re_field = quotemeta($field_term);
                            $re_field = qr/$re_field/i;
                        }
                        $expr_field .= " =~ " . Data::Dmp::dmp($re_field) . "]";
                        push @re_field, $re_field;
                    }
                    log_trace "CSel expression for selecting fields: <$expr_field>";
                }

                @matching_fields = Data::CSel::csel({
                    class_prefixes => ["Org::Element"],
                }, $expr_field, $entry);
                log_trace "Number of matching fields for entry #$i: %d", scalar(@matching_fields);

                if ($args{num_fields} && @matching_fields > $args{num_fields}) {
                    splice @matching_fields, $args{num_fields};
                }

                next ENTRY unless @matching_fields;
            }

            unless ($args{hide_entry}) {
                $res->[2] .= "** ";
                unless ($args{hide_category}) {
                    $res->[2] .= _highlight(
                        $clrtheme_obj,
                        $re_category,
                        $entry->parent->title->as_string) . "/";
                }
                $res->[2] .= _highlight(
                    $clrtheme_obj,
                    $re_entry,
                    $entry->title->as_string,
                );
                $res->[2] .= "\n";
            }

            my $re_field;
            $re_field = join "|", @re_field if @re_field;
            if ($args{detail}) {
                my $str = $entry->children_as_string;
                $str = _highlight(
                    $clrtheme_obj,
                    $re_field,
                    $str) if defined $re_field;
                $res->[2] .= $str;
            } elsif (@matching_fields) {
                for my $field (@matching_fields) {
                    my $field_name0 = $field->desc_term->text;
                    unless ($args{hide_field_name}) {
                        my $field_name = '';
                        $field_name = _highlight(
                            $clrtheme_obj,
                            $re_field,
                            $field->bullet . ' ' . $field_name0,
                        ) . " ::";
                        unless ($args{clipboard} && $args{clipboard} eq 'only') {
                            $res->[2] .= $field_name;
                        }
                    }

                    my $field_value_formatter_from_rules;
                    my $field_value_formatter_filters_from_rules;
                  SET_FIELD_VALUE_FORMATTERS_FROM_RULES:
                    {
                        last if $args{no_field_value_formatters};
                        last if $field_value_formatter_from_args;
                        last unless $args{field_value_formatter_rules} && @{ $args{field_value_formatter_rules} };

                        $field_value_formatter_filters_from_rules = [];
                        my $field_value_formatters_from_rules = [];
                        unless (@parsed_field_value_formatter_rules) {
                            my $i = -1;
                            for my $r0 (@{ $args{field_value_formatter_rules} }) {
                                $i++;
                                my $r;
                                if (!ref($r0) && $r0 =~ /\A\{/) {
                                    require JSON::PP;
                                    $r = JSON::PP::decode_json($r0);
                                } else {
                                    $r = {%$r0};
                                }

                                # precompile regexes
                                require Regexp::From::String;
                                if (defined $r->{field_name_matches}) {
                                    $r->{field_name_matches} = Regexp::From::String::str_to_re({case_insensitive=>1}, $r->{field_name_matches});
                                }

                                if ($r->{formatters} && @{ $r->{formatters} }) {
                                    my @filter_names;
                                    for my $f (@{ $r->{formatters} }) {
                                        if ($f =~ /\A\[/) {
                                            require JSON::PP;
                                            $f = JSON::PP::decode_json($f);
                                        } else {
                                            if ($f =~ /(.+)=(.*)/) {
                                                my ($modname, $args) = ($1, $2);
                                                # normalize / to :: in the module name part
                                                $modname =~ s!/!::!g;
                                                $f = [$modname, { split /,/, $args }];
                                            } else {
                                                # normalize / to ::
                                                $f =~ s!/!::!g;
                                            }
                                        }
                                        push @filter_names, $f;
                                    }
                                    require Data::Sah::Filter;
                                    $r->{formatter} = Data::Sah::Filter::gen_filter(
                                        filter_names => \@filter_names,
                                        return_type => 'str_errmsg+val',
                                    );
                                    push @{ $field_value_formatter_filters_from_rules }, \@filter_names;
                                } else {
                                    die "Field value formatting rules [$i] does not have non-empty formatters: %s", $r;
                                }
                                push @parsed_field_value_formatter_rules, $r;
                            }
                            #log_error "parsed_field_value_formatter_rules=%s", \@parsed_field_value_formatter_rules;
                        } # set @parsed_field_value_formatter_rules

                        # do the filtering
                        my $i = -1;
                      RULE:
                        for my $r (@parsed_field_value_formatter_rules) {
                            $i++;
                            my $matches = 1;
                            if (defined $r->{field_name_matches}) {
                                $field_name0 =~ $r->{field_name_matches} or do {
                                    $matches = 0;
                                    log_trace "Skipping field_value_formatter_rules[%d]: field_name_matches %s doesn't match %s", $i, $r->{field_name_matches}, $field_name0;
                                    next RULE;
                                };
                            }
                            if (defined $r->{hide_field_name}) {
                                if ($args{hide_field_name} xor $r->{hide_field_name}) {
                                    $matches = 0;
                                    log_trace "Skipping field_value_formatter_rules[%d]: hide_field_name condition (%s) doesn't match actual hide_field_name option (%s)", $i, ($r->{hide_field_name} ? 'true':'false'), ($args{hide_field_name} ? 'true':'false');
                                    next RULE;
                                }
                            }
                            log_trace "Adding field value formatters from field_value_formatter_rules[%d] (%s) for field name %s", $i, $r->{formatters}, $field_name0;
                            push @$field_value_formatters_from_rules, $r->{formatter};
                        }
                        # combine default formatters
                        last unless @$field_value_formatters_from_rules;
                        if (@$field_value_formatters_from_rules > 1) {
                            $field_value_formatter_from_rules = sub {
                                my $val = shift;
                                my $res;
                                for my $i (0 .. $#{$field_value_formatters_from_rules}) {
                                    $res = $field_value_formatters_from_rules->[$i]->($val);
                                    return $res if $res->[0];
                                    $val = $res->[1];
                                }
                                $res;
                            };
                        } else {
                            $field_value_formatter_from_rules = $field_value_formatters_from_rules->[0];
                        }
                    } # SET_FIELD_VALUE_FORMATTERS_FROM_RULES

                    my $field_value0 = $field->children_as_string;
                    my ($prefix, $field_value, $suffix) = $field_value0 =~ /\A(\s+)(.*?)(\s*)\z/s;
                    my ($field_value_formatter, $field_value_formatter_filters);
                    if ($field_value_formatter_from_args) {
                        $field_value_formatter = $field_value_formatter_from_args;
                        $field_value_formatter_filters = $field_value_formatter_filters_from_args;
                    } elsif ($field_value_formatter_from_rules) {
                        $field_value_formatter = $field_value_formatter_from_rules;
                        $field_value_formatter_filters = $field_value_formatter_filters_from_rules;
                    }
                    if ($field_value_formatter) {
                        my ($ferr, $fres) = @{ $field_value_formatter->($field_value) };
                        if ($ferr) {
                            log_warn "Field value formatting error: formatter=%s, field value=%s, errmsg=%s", $field_value_formatter_filters, $field_value, $ferr;
                            $field_value = "$field_value # CAN'T FORMAT: $ferr";
                        } else {
                            $field_value = $fres;
                        }
                    }
                    unless ($args{clipboard} && $args{clipboard} eq 'only') {
                        $res->[2] .= ($args{hide_field_name} ? "" : $prefix) . $field_value . $suffix;
                    }
                    push @outputted_field_values, $field_value;
                }
            }
        }
    }

  COPY_TO_CLIPBOARD: {
        last unless $args{clipboard};
        last unless @outputted_field_values;
        require Clipboard::Any;
        log_info "Copying matching field values to clipboard ...";
        my $res = Clipboard::Any::add_clipboard_content(content => join "\n", @outputted_field_values);
        if ($res->[0] != 200) {
            log_warn "Cannot copy to clipboard: $res->[0] - $res->[1]";
            last;
        }
    }

    $res;
}

sub _select_shell {
    my %args = @_;

    require App::orgadb::Select::Shell;
    my $shell = App::orgadb::Select::Shell->new(
        main_args => \%args,
    );

    $shell->cmdloop;
    [200];
}

$SPEC{select} = {
    v => 1.1,
    summary => 'Select Org addressbook entries/fields/subfields',
    args => {
        %App::orgadb::Common::argspecs_common,
        %App::orgadb::Common::argspecs_select,
    },
    'x.envs' => {
        'ORGADB_COLOR_THEME' => {
            summary => 'Set default color theme',
            schema => 'perl::colortheme::modname_with_optional_args*',
            description => <<'MARKDOWN',

Color theme is Perl module name under the `ColorTheme::Search::` namespace,
without the namespace prefix. The default is `Light`. You can set color theme
using the `--color-theme` command-line option as well as this environment
variable.

MARKDOWN
        },
    },
};
sub select {
    my %args = @_;

    return [400, "Please specify at least one file"] unless @{ $args{files} || [] };

    my $code_parse_files = sub {
        my @filenames = @_;

        my @trees;
        my @tree_filenames;

        require Org::Parser;
        my $parser = Org::Parser->new;

        for my $filename (@filenames) {
            my $doc;
            if ($filename eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $doc = $parser->parse(join "", <>);
            } else {
                local $ENV{PERL_ORG_PARSER_CACHE} = $ENV{PERL_ORG_PARSER_CACHE} // 1;
                if ($filename =~ /\.gpg\z/) {
                    require IPC::System::Options;
                    my $content;
                    IPC::System::Options::system(
                        {log=>1, capture_stdout=>\$content, die=>1},
                        "gpg", "-d", $filename);
                    $doc = $parser->parse($content);
                } else {
                    $doc = $parser->parse_file($filename);
                }
            }
            push @trees, $doc;
            push @tree_filenames, $filename;
        } # for filename

        return (\@trees, \@tree_filenames);
    };

    if ($args{shell}) {
        _select_shell(
            _code_parse_files => $code_parse_files,
            %args,
        );
    } else {
        my ($trees, $tree_filenames) = $code_parse_files->(@{ $args{files} });
        _select_single(
            %args,
            _trees => $trees,
            _tree_filenames => $tree_filenames,
        );
    }
}

1;
# ABSTRACT: An opinionated Org addressbook toolset

__END__

=pod

=encoding UTF-8

=head1 NAME

App::orgadb - An opinionated Org addressbook toolset

=head1 VERSION

This document describes version 0.020 of App::orgadb (from Perl distribution App-orgadb), released on 2025-06-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes the following CLI's:

=over

=item * L<orgadb-sel>

=back

=head1 FUNCTIONS


=head2 select

Usage:

 select(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select Org addressbook entriesE<sol>fieldsE<sol>subfields.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str_or_re>

Find entry by string or regex search against the category title.

=item * B<clipboard> => I<str>

Whether to copy matching field values to clipboard.

If set to C<tee>, then will display matching fields to terminal as well as copy
matching field values to clipboard.

If set to C<only>, then will not display matching fields to terminal and will
only copy matching field values to clipboard.

Mnemonic for short option C<-y> and C<-Y>: I<y>ank as in Emacs (C<C-y>).

=item * B<color> => I<str> (default: "auto")

Whether to use color.

=item * B<color_theme> => I<perl::colortheme::modname_with_optional_args>

(No description)

=item * B<count> => I<true>

Return just the number of matching entries instead of showing them.

=item * B<detail> => I<bool>

Instead of showing matching field values, display the whole entry.

Mnemonic for shortcut option C<-l>: the option C<-l> is usually used for the short
version of C<--detail>, as in I<ls> Unix command.

=item * B<entry> => I<str_or_re>

Find entry by string or regex search against its title.

=item * B<entry_match_mode> => I<str> (default: "default")

How entry should be matched.

The default matching mode is as follow:

 str       Substring matching
 /re/      Regular expression matching

If matching mode is set to C<exact>, then matching will be done by string
equality test. This mode is basically a shorter alternative to having to
specify:

 /^\Qre\E$/

Matching mode C<exact-ci> is like C<exact> except case-insensitive. It is
equivalent to:

 /^\Qre\E$/i

=item * B<field_match_mode> => I<str> (default: "default")

How entry should be matched.

The default matching mode is as follow:

 str       Substring matching
 /re/      Regular expression matching

If matching mode is set to C<exact>, then matching will be done by string
equality test. This mode is basically a shorter alternative to having to
specify:

 /^\Qre\E$/

Matching mode C<exact-ci> is like C<exact> except case-insensitive. It is
equivalent to:

 /^\Qre\E$/i

=item * B<field_value_formatter_rules> => I<array[hash]>

Specify field value formatters to use when conditions are met, specified as an
array of hashes. Each element is a rule that is as a hash containing condition
keys and formatters keys. If all conditions are met then the formatters will be
applied. The rules will be tested when each field is about to be outputted.
Multiple rules can match and the matching rules' formatters are all applied in
succession.

Note that this option will be overridden by the C<--field-value-formatter>
(C<-fvfmt>) or the C<--no-field-value-formatters> (C<-F>) option.

The rules are best specified in the configuration as opposed to on the
command-line option. An example (the lines below are writen in configuration
file in IOD syntax, as rows of JSON hashes):

 ; remove all comments in field values when 'hide_field_name' option is set
 ; (which usually means we want to copy paste things)
 
 field_value_formatter_rules={"hide_field_name":true, "formatters":[ ["Str::remove_comment"] ]}
 
 ; normalize phone numbers using Phone::format + Str::remove_whitespace when
 ; 'hide_field_name' option is set (which usually means we want to copy paste
 ; things). e.g. '0812-1234-5678' becomes '+6281212345678'.
 
 field_value_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i", "hide_field_name":true, "formatters":[ ["Phone::format", "Str::remove_whitespace"] ]}
 
 ; but if 'hide_field_name' field is not set, normalize phone numbers using
 ; Phone::format without removing whitespaces, which is easier to see (e.g.
 ; '+62 812 1234 5678').
 
 field_value_formatter_rules={"field_name_matches":"/phone|wa|whatsapp/i", "hide_field_name":false, "formatters":[ ["Phone::format"] ]}

Condition keys:

=over

=item * C<field_name_matches> (value: str/re): Check if field name matches a regex pattern.

=item * C<hide_field_name> (value: bool): Check if C<--hide-field-name> (C<-N>) option is
set (true) or unset (false).

=back

Formatter keys:

=over

=item * C<formatters>: an array of formatters, to be applied. Each formatter is a name
of perl Sah filter rule, or a two-element array of perl Sah filter rule name
followed by hash containing arguments. See C<--formatter> for more detais on
specifying formatter.

=back

=item * B<field_value_formatters> => I<array[str]>

Add one or more formatters to display field value.

Specify one or more formatters to apply to the field value before displaying.

A formatter is name of C<Data::Sah::Filter::perl::*> module, without the prefix.
For example: C<Str::uc> will convert the field value to uppercase. Another
formatter, C<Str::remove_comment> can remove comment.

A formatter can have arguments, which is specified using this format:

 [FORMATTER_NAME, {ARG1NAME => ARG1VAL, ...}]

If formatter name begins with C<[> character, it will be parsed as JSON. Example:

 ['Str::remove_comment', {'style':'cpp'}]

Note that this option overrides C<--field-value-formatter-rules> but is
overridden by the C<--no-field-value-formatters> (C<--raw-field-values>, C<-F>)
option.

=item * B<fields> => I<array[str_or_re]>

Find (sub)fields by string or regex search.

=item * B<files> => I<array[filename]>

Path to addressbook files.

=item * B<filter_entries_by_fields> => I<array[str]>

Find entry by the fields or subfields it has.

The format of each entry_by_field is one of:

 str
 /re/
 str = str2
 str = /re2/
 /re/ = str2
 /re/ = /re2/

That is, it can search for a string (C<str>) or regex (C<re>) in the field name,
and optionally also search for a string (C<str2>) or regex (C<re2>) in the field
value.

=item * B<hide_category> => I<true>

Do not show category.

=item * B<hide_entry> => I<true>

Do not show entry headline.

=item * B<hide_field_name> => I<true>

Do not show field names, just show field values.

Mnemonic for short option C<-N>: field I<N>ame (uppercase letter usually means
/no/).

=item * B<no_field_value_formatters> => I<true>

Do not apply formatters for field value (overrides --field-value-formatter option).

Note that this option has higher precedence than
C<--default-field-value-formatter-rules> or the C<--field-value-formatter>
(C<--fvfmt>) option.

=item * B<num_entries> => I<uint>

Specify maximum number of entries to return (0 means unlimited).

=item * B<num_fields> => I<uint>

Specify maximum number of fields (per entry) to return (0 means unlimited).

=item * B<reload_files_on_change> => I<bool> (default: 1)

(No description)

=item * B<shell> => I<true>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-orgadb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-orgadb>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-orgadb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
