package Daje::Helper::Kanban::Planboard;
use Mojo::Base -base, -signatures, -async_await;
use v5.42;

# NAME
# ====
#
# Daje::Helper::Authorities::InsertPluginFunction - Daje helper
#
# SYNOPSIS
# ========
#
#
# DESCRIPTION
# ===========
#
# Daje::Helper::Authorities::InsertPluginFunction a helper clas
#
# METHODS
# =======
#
#
#
#
# SEE ALSO
# ========
#
# Mojolicious, Mojolicious::Guides, https://mojolicious.org.
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.com
#

has 'db';


async sub planboard_load($self, $companies_pkey, $users_pkey, $kanban_planboard_pkey) {

    my $stmt = $self->get_statement();
    my $result->{result} = 0;

    my $load = $self->db->query($stmt, $kanban_planboard_pkey);
    $result->{data} = {};
    $result->{data} = $load->hash if $load and $load->rows > 0;
    $result->{result} = 1;
    return $result;
}

sub get_statement($self) {
    return qq{
select json_build_object('data', (SELECT json_agg(json_build_object(
									'kanban_list_pkey', kanban_list_pkey,
									'kanban_planboard_fkey',kanban_planboard_fkey,
									'sort_order', sort_order,
									'active', active,
                                    'title', title,
									'listid',listid,
                                    'cards',(
                                        SELECT coalesce(json_agg(
                                            json_build_object(
                                                'kanban_cards_pkey', kanban_cards_pkey,
                                                'kanban_list_fkey', kanban_list_fkey,
                                                'kanban_priority_fkey', kanban_priority_fkey,
                                                'sort_order', sort_order,
                                                'id', id,
                                                'title', title,
                                                'description', description,
                                                'progress', progress,
                                                'startdate', startdate,
                                                'duedate', duedate,
                                                'completed', completed,
                                                'priority', (
                                                    SELECT json_build_object(
                                                        'kanban_priority_pkey', kanban_priority_pkey,
                                                        'color', color,
                                                        'title', title
                                                    )
                                                        FROM kanban_priority WHERE kanban_priority_pkey = kanban_priority_fkey
                                                ),
                                                'taskList',(SELECT coalesce(json_agg(json_build_object(
                                                    'kanban_tasks_pkey', kanban_tasks_pkey,
                                                    'kanban_cards_fkey',kanban_cards_fkey,
                                                    'id', id,
                                                    'title', title,
                                                    'booked', booked,
                                                    'estimated', estimated,
                                                    'completed', completed,
                                                    'tasks', (
                                                        SELECT json_agg(json_build_object(
                                                            'kanban_task_pkey', kanban_task_pkey,
                                                            'kanban_tasks_fkey', kanban_tasks_fkey,
                                                            'text', text,
                                                            'completed', completed
                                                        ))
                                                            FROM kanban_task WHERE kanban_tasks_pkey = kanban_tasks_fkey
                                                        )
                                                    )
                                                ), '{"tasks":[]}'::json)
                                                    FROM kanban_tasks WHERE kanban_cards_pkey = kanban_cards_fkey
                                                ),
                                                'comments', (
                                                        SELECT coalesce(json_agg(json_build_object(
                                                            'kanban_comments_pkey', kanban_comments_pkey,
                                                            'kanban_cards_fkey', kanban_cards_fkey,
                                                            'users_users_fkey', users_users_fkey,
                                                            'id', id,
                                                            'text', text
                                                        )
                                                    ), '[]'::json) FROM kanban_comments WHERE kanban_cards_pkey = kanban_cards_fkey
                                                ),
                                                'assignees', (SELECT coalesce(json_agg(json_build_object(
                                                    'users_users_fkey', users_users_fkey,
                                                    'comment', comment
                                                )), '[]'::json) FROM kanban_assignees WHERE kanban_cards_pkey = kanban_cards_fkey)

                                            )
                                        ), '[]'::JSON) FROM kanban_cards WHERE kanban_list_fkey = kanban_list_pkey
                                    )
                                )
							)
						FROM kanban_list WHERE kanban_planboard_fkey = ?
                    )
				)

    };
}
1;