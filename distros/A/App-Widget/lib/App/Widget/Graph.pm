
######################################################################
## $Id: Graph.pm 13300 2009-09-10 20:26:36Z spadkins $
######################################################################

package App::Widget::Graph;
$VERSION = (q$Revision: 13300 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Widget;
@ISA = ( "App::Widget" );

use strict;

=head1 NAME

App::Widget::Graph - A graph for displaying data using HTML tables for bar graphs

=head1 SYNOPSIS

   $name = "first_name";

   # official way
   use App;
   $context = App->context();
   $w = $context->widget($name);
   # OR ...
   $w = $context->widget($name,
      class => "App::Widget::Graph",
   );

   # internal way
   use App::Widget::Graph;
   $w = App::Widget::Graph->new($name);

=cut

=head1 DESCRIPTION

A graph for displaying data using HTML tables for bar graphs.

=cut

sub html {
    &App::sub_entry if ($App::trace);
    my $self = shift;
    my ($name, $value, $html_value, $html);
    $name = $self->{name};
    my $x_values = $self->{x};
    my $y_values = $self->{y};
    my $y_max = $self->{y_max};
    my $y_width = $self->{width} || 300;
    $html = "<table cellpadding=0 border=0 cellspacing=5>\n";
    my ($x_value, $y_value, $width, $x_cell);
    $y_max = 0;
    for (my $i = 0; $i <= $#$y_values; $i++) {
        $y_value = $y_values->[$i];
        if ($y_max < $y_value) {
            $y_max = $y_value;
        }
    }
    $y_max = 1 if ($y_max == 0);
    $x_cell = "";
    for (my $i = 0; $i <= $#$y_values; $i++) {
        if ($x_values) {
            $x_value = $x_values->[$i];
            $x_cell = "<td align=\"right\">$x_value</td>";
        }
        $y_value = $y_values->[$i];
        $y_value = $y_max if ($y_max && $y_value > $y_max);
        $width = ($y_value/$y_max) * $y_width;
        $html .= "  <tr>$x_cell<td>\n";
        $html .= "    <table border=0 cellpadding=0 cellspacing=0><tr><td width=\"$width\" bgcolor=\"red\"></td>";
        $html .= "<td>&nbsp;$y_value</td></tr></table>\n";
        $html .= "  </td></tr>\n";
    }
    $html .= "</table>\n";
    &App::sub_exit() if ($App::trace);
    $html;
}

sub get_x {
    &App::sub_entry if ($App::trace);
    my ($self, $spec) = @_;
    $self->load_data($spec) if (!$spec->{y});
    my $x = $spec->{x};

    &App::sub_exit($x) if ($App::trace);
    return($x);
}

sub get_y {
    &App::sub_entry if ($App::trace);
    my ($self, $spec) = @_;
    $self->load_data($spec) if (!$spec->{y});
    my $yn = [];
    my ($y);

    if ($spec->{y}) {
        $y = $spec->{y};
        if (ref($y->[0]) eq "ARRAY") {
            $yn = $y;
        }
        else {
            push(@$yn, $y);
            my $series = 2;
            $y = $spec->{"y$series"};
            while ($y) {
                push(@$yn, $y);
                $series++;
                $y = $spec->{"y$series"};
            }
        }
    }

    &App::sub_exit($yn) if ($App::trace);
    return($yn);
}

sub get_object_set {
    &App::sub_entry if ($App::trace);
    my ($self, $spec) = @_;
    $spec = $self if (!$spec);
    my $name = $self->{name};
    my $context = $self->{context};

    #my $object_set_name = $spec->{object_set} || "$name-object_set";
    my $object_set = $spec->{object_set};

    if (!$object_set) {
        $object_set = $context->session_object("$name-object_set");
    }
    elsif (! ref $object_set) {
        $object_set = $context->session_object($object_set, class => "App::SessionObject::RepositoryObjectSet");
    }
    elsif ($spec->{domain}) {
        my $domain_name = $spec->{domain};
        my $table = $spec->{table};
        my $domain = $context->session_object($domain_name);
        $object_set = $domain->get_object_set($table);
    }
    &App::sub_exit($object_set) if ($App::trace);
    return($object_set);
}

sub load_data {
    &App::sub_entry if ($App::trace);
    my ($self, $spec) = @_;

    my $context = $self->{context};

    # the following four fields need to be set to bind
    my $columns = $spec->{columns};
    $columns = [ split(/,/, $columns) ] if (!ref($columns));
    die "no columns in graph" if ($#$columns == -1);

    my $keys = $self->{keys};
    $keys = [ split(/,/, $keys) ] if (!ref($keys));

    my ($objects, $summary_keys, $graph_keys, $column_defs, $object_set);

    if ($self->{objects}) {
        $objects      = $self->{objects};
        $summary_keys = $self->{summary_keys};
        $column_defs  = $self->{column_defs};
    }
    else {
        $object_set = $self->get_object_set($spec);
        die "No known way to get data" if (!$object_set);
        # make sure that the columns we need for the graph are in the
        # list of columns in the object_set
        $object_set->include_columns($columns);
        $objects      = $object_set->get_objects();
        $summary_keys = $object_set->get_key_columns();  # get the columns that are keys
        $column_defs  = $object_set->get_column_defs();
    }

    # if the number of columns is more than 1, then the inner-most dimension is the different columns
    my $column_dims        = (($#$columns > 0) ? 1 : 0);
    my $max_graphtype_dims = $self->get_num_dims($spec->{graphtype});
    my $max_data_dims      = $max_graphtype_dims - $column_dims;

    if (!$keys) {
        if ($summary_keys) {
            $keys = [@$summary_keys];
        }
        else {
            $keys = [];
        }
    }

    my $needs_summarization = 0;
    if (!$summary_keys) {
        $needs_summarization = 1;
    }
    else {
        my $new_keys = [];
        my (%key_avail, $key);
        foreach $key (@$summary_keys) {
            $key_avail{$key} = 1;
            #print STDERR "\$key_avail{$key} = 1\n";
        }
        foreach $key (reverse @$keys) {
            #print STDERR "  \$key = [$key]\n";
            last if ($#$new_keys + 1 >= $max_data_dims);
            if ($key_avail{$key}) {
                #print STDERR "     UNSHIFTED \$key = [$key]\n";
                unshift(@$new_keys, $key);
            }
        }
        if ($#$new_keys != $#$summary_keys) {
            $needs_summarization = 1;
        }
        $keys = $new_keys;
    }

    if ($needs_summarization && $#$objects > -1) {
        my $rep = $objects->[0]{_repository} || $self->{context}->repository();
        #print STDERR "needs_summarization keys = [@$keys] rows before [", ($#$objects + 1), "]\n";
        #print STDERR " row {", join("|", %{$objects->[0]}), "]\n";
        $objects = $rep->summarize_rows($spec->{table}, $objects, undef, $keys);
        #print STDERR "needs_summarization keys = [@$keys] rows after  [", ($#$objects + 1), "]\n";
        #print STDERR " row {", join("|", %{$objects->[0]}), "]\n";
    }

    my (@x, @yn, $object, $column, $x, $yn);
    my ($label, $format, $yn_val);

    my $data_dims   = ($#$keys + 1) + $column_dims;
    if ($#$columns > 0 || $data_dims < 2) {
        for (my $i = 0; $i <= $#$objects; $i++) {
            $object = $objects->[$i];
            for (my $j = 0; $j <= $#$columns; $j++) {
                $column = $columns->[$j];
                $format = $column_defs->{$column}{format};
                $yn_val = $object->{$column};

                if ($format && $format =~ /%/) {
                    if ($yn_val ne "") {
                        $yn_val = App::Widget->format($yn_val, $column_defs->{$column});
                        $yn_val =~ s/%//;
                    }
                }
                elsif ($format && $format =~ /\s+\((?:\/)?\d+\)/) {
                    if ($yn_val ne "") {
                        $yn_val = App::Widget->format($yn_val, $column_defs->{$column});
                    }
                }

                # A special constant called NoValue, which is equal to 1.7E+308.
                # When ChartDirector sees that a data point is NoValue, it will jump over that point
                $yn_val = 1.7e+308 if ($yn_val eq "");

                $yn[$j][$i] = $yn_val;
            }
        }

        for ($yn = 0; $yn <= $#yn; $yn ++) {
            for ($x = 0; $x <= $#x; $x ++) {
                if (! defined $yn[$yn][$x]) {
                    $yn[$yn][$x] = 0;
                }
            }
        }

        $spec->{y} = \@yn;

        if ($column_dims) {
            my (@y_labels);
            foreach my $column (@$columns) {
                $label = $column_defs->{$column}{label} || $column;
                $label =~ s/<br>//g;
                push(@y_labels, $label);
            }
            $spec->{y_labels} = \@y_labels;
        }

        my $x_dim = $#$keys;
        my $x_column = $keys->[$x_dim];
        $label = $column_defs->{$x_column}{label};
        $label =~ s/<br>//g;
        $spec->{x_title} = $label if (!$spec->{x_title});
        my (@x, %x_seen, $x_value);
        foreach my $object (@$objects) {
            $x_value = $object->{$x_column};
            if (!$x_seen{$x_value}) {
                push(@x, $x_value);
                $x_seen{$x_value} = 1;
            }
        }

        foreach my $graph_key (@$keys) {
            if ($graph_key =~ /^dow$/) {
                my @x_new;
                my $value_domain = $context->value_domain($column_defs->{$graph_key}{domain});
                my $labels       = $value_domain->labels();
                foreach my $x_val (@x) {
                    push(@x_new, $labels->{$x_val});
                }
                @x = @x_new;
            }
            else {
                my ($val_sort, $vals_sort_idx, $sign, @x_new, @yn_new, $graph_key_vals);
                my %numeric = ( "integer" => 1, "float" => 1 );

                if ($spec->{params}{$graph_key}) {
                    $graph_key_vals = [ split(/,/, $spec->{params}{$graph_key}) ];
                    for (my $i = 0; $i <= $#$graph_key_vals; $i++) {
                        $val_sort->{$graph_key}{$graph_key_vals->[$i]} = $i;
                    }
                }
                else {
                    next if (!$column_defs->{$graph_key}{domain});
                    my $value_domain = $context->value_domain($column_defs->{$graph_key}{domain});
                    my $domain_vals  = $value_domain->values();
                    for (my $i = 0; $i <= $#$domain_vals; $i++) {
                       $val_sort->{$graph_key}{$domain_vals->[$i]} = $i;
                    }
                }

                @$vals_sort_idx = sort {
                    $sign = 0;
                    for (my $i = 0; $i <= $#x; $i++) {
                        my $val_a = $x[$a];
                        my $val_b = $x[$b];
                        $sign = (defined $val_sort->{$graph_key}) ?
                            ($val_sort->{$graph_key}{$val_a} <=> $val_sort->{$graph_key}{$val_b}) :
                            ($numeric{$column_defs->{$graph_key}{type}} ? ($val_a <=> $val_b) : ($val_a cmp $val_b));
                        last if ($sign);
                    }
                    $sign;
                } (0 .. $#x);

                for (my $i = 0; $i <= $#$vals_sort_idx; $i++) {
                    push(@x_new, $x[$vals_sort_idx->[$i]]);
                }
                for (my $i = 0; $i <= $#$vals_sort_idx; $i++) {
                    for (my $j = 0; $j <= $#$columns; $j++) {
                        $yn_new[$j][$i] = $yn[$j][$vals_sort_idx->[$i]]
                    }
                }

                @x = @x_new;
                $spec->{y} = \@yn_new;
            }
        }

        $spec->{x} = \@x;
    }
    else {  # there is only one column ($#$columns == 0)
        my $x_dim = $#$keys - 1;
        my $x_column = $keys->[$x_dim];
        my $y_dim = $#$keys;
        my $y_column = $keys->[$y_dim];
        my $column = $columns->[0];
        $format = $column_defs->{$column}{format};
        $label = $column_defs->{$x_column}{label};
        $label =~ s/<br>//g;
        $spec->{x_title} = $label if (!$spec->{x_title});
        my (@x, %x_idx, $x_value, @y, %y_idx, $y_value);

        foreach my $object (@$objects) {
            $x_value = $object->{$x_column};
            $y_value = $object->{$y_column};
#print STDERR "x_column=[$x_column] [$column_defs->{$x_column}{domain}] x_value=[$x_value]\n";
#print STDERR "y_column=[$y_column] [$column_defs->{$y_column}{domain}] y_value=[$y_value]\n";
            if (! defined $x_idx{$x_value}) {
                my $val_domain = $column_defs->{$x_column}{domain};
                if (defined $val_domain) {
                    my $new_x_val = App::Widget->format($x_value, { domain => $val_domain});
                    push(@x, $new_x_val);
                }
                else {
                    push(@x, $x_value);
                }
                $x_idx{$x_value} = $#x;
            }
            if (! defined $y_idx{$y_value}) {
                my $val_domain = $column_defs->{$y_column}{domain};
                if (defined $val_domain) {
#print STDERR "y_column=[$y_column] [$column_defs->{$y_column}{domain}] y_value=[$y_value]\n";
                    my $new_y_val = App::Widget->format($y_value, { domain => $val_domain});
                    push(@y, $new_y_val);
                }
                else {
                    push(@y, $y_value);
                }
                $y_idx{$y_value} = $#y;
            }
            $yn_val = $object->{$column};

            if ($format && $format =~ /%/) {
                if ($yn_val ne "") {
                    $yn_val = App::Widget->format($yn_val, $column_defs->{$column});
                    $yn_val =~ s/%//;
                }
            }
            elsif ($format && $format =~ /\s+\((?:\/)?\d+\)/) {
                if ($yn_val ne "") {
                    $yn_val = App::Widget->format($yn_val, $column_defs->{$column});
                }
            }

            # A special constant called NoValue, which is equal to 1.7E+308.
            # When ChartDirector sees that a data point is NoValue, it will jump over that point
            $yn_val = 1.7e+308 if ($yn_val eq "");

            $yn[$y_idx{$y_value}][$x_idx{$x_value}] = $yn_val;
        }

        for ($yn = 0; $yn <= $#yn; $yn ++) {
            for ($x = 0; $x <= $#x; $x ++) {
                if (! defined $yn[$yn][$x]) {
                    $yn[$yn][$x] = 0;
                }
            }
        }

        foreach my $graph_key (@$keys) {
            my ($graph_key_vals, $val_sort, $vals_sort_idx, $sign, @yn_new, @y_new);
            my %numeric = ( "integer" => 1, "float" => 1 );

            if ($spec->{params}{$graph_key}) {
                $graph_key_vals = [ split(/,/, $spec->{params}{$graph_key}) ];
            }
            else {
                next;
            }

            for (my $i = 0; $i <= $#$graph_key_vals; $i++) {
                $val_sort->{$graph_key}{$graph_key_vals->[$i]} = $i;
            }

            @$vals_sort_idx = sort {
                $sign = 0;
                for (my $i = 0; $i <= $#y; $i++) {
                    my $val_a = $y[$a];
                    my $val_b = $y[$b];
                    $sign = (defined $val_sort->{$graph_key}) ?
                        ($val_sort->{$graph_key}{$val_a} <=> $val_sort->{$graph_key}{$val_b}) :
                        ($numeric{$column_defs->{$graph_key}{type}} ? ($val_a <=> $val_b) : ($val_a cmp $val_b));
                    last if ($sign);
                }
                $sign;
            } (0 .. $#y);

            if ($#$vals_sort_idx != -1) {
                for (my $i = 0; $i <= $#$vals_sort_idx; $i++) {
                    push(@yn_new, $yn[$vals_sort_idx->[$i]]);
                }
                for (my $i = 0; $i <= $#$vals_sort_idx; $i++) {
                    $y_new[$i] = $y[$vals_sort_idx->[$i]]
                }

                @y  = @y_new;
                @yn = @yn_new;
            }
        }

        $spec->{x} = \@x;
        $spec->{y} = \@yn;
        $spec->{y_labels} = \@y;
    }

    &App::sub_exit() if ($App::trace);
}

sub get_y_limits {
    &App::sub_entry if ($App::trace);
    my ($self, $spec) = @_;
    my $y_min = 0;
    my $y_max = 0;
    my $yn = $self->get_y($spec);
    my $graphtype = $spec->{graphtype} || "bar";

    # stacked types
    if ($graphtype eq "stacked_bar" || $graphtype eq "area") {
        my (@y_values);
        foreach my $y (@$yn) {
            foreach (my $i = 0; $i <= $#$y; $i++) {
                $y_values[$i] += $y->[$i];
                $y_min = $y_values[$i] if ($y_min > $y_values[$i]);
                $y_max = $y_values[$i] if ($y_max < $y_values[$i]);
            }
        }
    }
    else {
        foreach my $y (@$yn) {
            foreach (my $i = 0; $i <= $#$y; $i++) {
                $y_min = $y->[$i] if ($y_min > $y->[$i]);
                $y_max = $y->[$i] if ($y_max < $y->[$i]);
            }
        }
    }
    &App::sub_exit($y_min, $y_max) if ($App::trace);
    return($y_min, $y_max);
}

1;

