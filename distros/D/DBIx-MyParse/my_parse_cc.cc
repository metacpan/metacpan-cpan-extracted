/*
   DBIx::MyParse - a glue between Perl and MySQL's SQL parser
   Copyright (C) 2005 - 2007 Philip Stoev

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#define EMBEDDED_LIBRARY
#define MYSQL_SERVER

#include <sql/mysql_priv.h>
#include <mysql.h>
#include <libmysqld/embedded_priv.h>

#include <my_parse.h>

#include <my_enum.h>
#include <my_define.h>

static THD * global_thd;

perl_object * my_parse_inner(THD * thd, st_select_lex * select_lex, bool in_subquery);

perl_object * my_parse_item(THD * thd, Item * item);

perl_object * my_parse_tables_obj(THD * thd, st_select_lex * select_lex, perl_object * query_perl, List<TABLE_LIST> * tables);

perl_object * my_parse_tables_list(THD * thd, st_select_lex * select_lex, perl_object * query_perl, TABLE_LIST * start_table);

perl_object * my_parse_list_items(THD * thd, perl_object * query_perl, List<Item> list) {

	perl_object * array_perl = my_parse_create_array();

	List_iterator_fast<Item> iterator(list);
	Item *item;

	while ((item = iterator++)) {
		my_parse_set_array(
			array_perl,
			MYPARSE_ARRAY_APPEND,
			my_parse_item(thd, item),
			MYPARSE_ARRAY_REF
		);
	}

	return array_perl;
}

perl_object * my_parse_list_strings(List<String> list) {
	perl_object * array_perl = my_parse_create_array();
	List_iterator_fast<String> iterator(list);
	String *str;
	while ((str = iterator++)) {
		my_parse_set_array( array_perl, MYPARSE_ARRAY_APPEND, (void *) str->ptr(), MYPARSE_ARRAY_STRING);
	}

	return array_perl;	
}

perl_object * my_parse_table(THD * thd, st_select_lex * select_lex, perl_object * query_perl, perl_object * join_perl, st_table_list * table) {

	perl_object * table_perl = my_parse_create_array();

	if (table->alias) {	
		my_parse_set_array( table_perl, MYPARSE_ITEM_ALIAS, (void *) table->alias, MYPARSE_ARRAY_STRING);
	}

	if (table->outer_join == JOIN_TYPE_LEFT) {
		my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_TYPE, (void *) "JOIN_TYPE_LEFT", MYPARSE_ARRAY_STRING);
	} else if (table->outer_join == JOIN_TYPE_RIGHT) {
		my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_TYPE, (void *) "JOIN_TYPE_RIGHT", MYPARSE_ARRAY_STRING);
	} else if (table->straight == 1) {
		my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_TYPE, (void *) "JOIN_TYPE_STRAIGHT", MYPARSE_ARRAY_STRING);
	} else if (table->natural_join) {
		my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_TYPE, (void *) "JOIN_TYPE_NATURAL", MYPARSE_ARRAY_STRING);
	}

	if (table->embedding) {
		TABLE_LIST * join_table = table->embedding;

		if (join_table->join_using_fields) {
			perl_object * join_fields_perl = my_parse_create_array();
			my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_FIELDS, join_fields_perl, MYPARSE_ARRAY_REF);
			List_iterator_fast<String> iterator(*join_table->join_using_fields);
			String *str;
			while ((str = iterator++)) {
				perl_object * join_field_perl = my_parse_create_array();
				perl_object * join_field_perl_ref = my_parse_bless(join_field_perl, MYPARSE_ITEM_CLASS);
				my_parse_set_array( join_field_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "FIELD_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( join_field_perl, MYPARSE_ITEM_FIELD_NAME, (void *) str->ptr(), MYPARSE_ARRAY_STRING);
				my_parse_set_array( join_fields_perl, MYPARSE_ARRAY_APPEND, join_field_perl_ref, MYPARSE_ARRAY_REF);
			}
		}
	}

	if (table->on_expr) {
		perl_object * join_cond_perl = my_parse_item(thd, table->on_expr);
		my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_COND, join_cond_perl, MYPARSE_ARRAY_REF);
	}

	if (table->table_name) {
		my_parse_set_array( table_perl, MYPARSE_ITEM_TABLE_NAME, (void *) table->table_name, MYPARSE_ARRAY_STRING);
	}

	if (thd->lex->orig_sql_command == SQLCOM_SHOW_TABLES) {
		my_parse_set_array( table_perl, MYPARSE_ITEM_DB_NAME, select_lex->db, MYPARSE_ARRAY_STRING);
	} else if (table->db) {
		my_parse_set_array( table_perl, MYPARSE_ITEM_DB_NAME, (void *) table->db, MYPARSE_ARRAY_STRING);
	}

	if (table->lock_type) {
		char lock_option[255];
		my_parse_thr_lock_type(table->lock_type, lock_option);
		perl_object * options_perl = my_parse_get_array( query_perl, MYPARSE_QUERY_OPTIONS );
		my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) lock_option, MYPARSE_ARRAY_STRING);
	}

	if (table->use_index) {
		perl_object * use_perl = my_parse_list_strings( *table->use_index );

		if (table->force_index) {
			my_parse_set_array( table_perl, MYPARSE_ITEM_FORCE_INDEX, use_perl, MYPARSE_ARRAY_REF);
		} else {
			my_parse_set_array( table_perl, MYPARSE_ITEM_USE_INDEX, use_perl, MYPARSE_ARRAY_REF);
		}
	}

	if (table->ignore_index) {
		perl_object * ignore_perl = my_parse_list_strings( *table->ignore_index );
		my_parse_set_array( table_perl, MYPARSE_ITEM_IGNORE_INDEX, ignore_perl, MYPARSE_ARRAY_REF);
	}

	if (table->nested_join) {
		perl_object * join_items_perl = my_parse_tables_obj( thd, select_lex, query_perl, &table->nested_join->join_list);
		my_parse_free_array(table_perl);
		return join_items_perl;
	} else if (table->derived) {
                my_parse_set_array( table_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "SUBSELECT_ITEM", MYPARSE_ARRAY_STRING);

		st_select_lex_unit * unit = table->derived;
		SELECT_LEX *sl = unit->first_select();

		perl_object * subselect_perl = my_parse_inner(unit->thd, sl, 1);
		my_parse_set_array( table_perl, MYPARSE_ITEM_SUBSELECT_QUERY, subselect_perl, MYPARSE_ARRAY_REF);
	} else {
		my_parse_set_array( table_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "TABLE_ITEM", MYPARSE_ARRAY_STRING);
	}

	perl_object * table_perl_ref = my_parse_bless(table_perl, MYPARSE_ITEM_CLASS);
	return table_perl_ref;
}

perl_object * my_parse_tables_obj(THD * thd, st_select_lex * select_lex, perl_object * query_perl, List<TABLE_LIST> * tables) {

	List_iterator_fast<TABLE_LIST> ti(*tables);
	TABLE_LIST **table = (TABLE_LIST **)thd->alloc(sizeof(TABLE_LIST*) * tables->elements);

	for (TABLE_LIST **t= table + (tables->elements - 1); t >= table; t--) {
		*t= ti++;
	}

	if (tables->elements == 1) {
		perl_object * table_perl = my_parse_table(thd, select_lex, query_perl, query_perl, *table );
		return table_perl;
	} else {
		TABLE_LIST **end= table + tables->elements;

		perl_object * join_perl = my_parse_create_array();
		perl_object * join_perl_ref = my_parse_bless(join_perl, MYPARSE_ITEM_CLASS);

		my_parse_set_array( join_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "JOIN_ITEM", MYPARSE_ARRAY_STRING);

		perl_object * join_items_perl = my_parse_create_array();
		my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_ITEMS, join_items_perl, MYPARSE_ARRAY_REF);

		for (TABLE_LIST **tbl= table; tbl < end; tbl++) {
			TABLE_LIST *curr= *tbl;
			perl_object * table_perl = my_parse_table(thd, select_lex, query_perl, join_perl, curr);
			my_parse_set_array( join_items_perl, MYPARSE_ARRAY_APPEND, table_perl, MYPARSE_ARRAY_REF);
		}
		return join_perl_ref;
	}
}

perl_object * my_parse_tables_list(THD * thd, st_select_lex * select_lex, perl_object * query_perl, TABLE_LIST * start_table) {

	perl_object * tables_perl = my_parse_create_array();

	if (start_table->next_global) {
		TABLE_LIST * table = NULL;
		perl_object * join_perl = my_parse_create_array();

		for (table = start_table ; table ; table = table->next_global) {
			perl_object * table_perl = my_parse_table(thd, select_lex, query_perl, join_perl, table);
			my_parse_set_array( tables_perl, MYPARSE_ARRAY_APPEND, table_perl, MYPARSE_ARRAY_REF);
		}

		if (
			(thd->lex->sql_command == SQLCOM_SELECT) ||
			(thd->lex->sql_command == SQLCOM_INSERT_SELECT) ||
			(thd->lex->sql_command == SQLCOM_REPLACE_SELECT) ||
			(thd->lex->sql_command == SQLCOM_DELETE_MULTI)
		) {
			perl_object * join_perl_ref = my_parse_bless(join_perl, MYPARSE_ITEM_CLASS);
			my_parse_set_array( join_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "JOIN_ITEM", MYPARSE_ARRAY_STRING);
			my_parse_set_array( join_perl, MYPARSE_ITEM_JOIN_ITEMS, tables_perl, MYPARSE_ARRAY_REF);
			return join_perl_ref;
		} else {
			return tables_perl;
		}
	} else {
		perl_object * table_perl = my_parse_table(thd, select_lex, query_perl, tables_perl, start_table );
		my_parse_set_array( tables_perl, MYPARSE_ARRAY_APPEND, table_perl, MYPARSE_ARRAY_REF);
		return tables_perl;
	}

}

perl_object * my_parse_schema_select(LEX * lex, st_select_lex * select_lex) {

	perl_object * item_perl = my_parse_create_array();
	perl_object * item_perl_ref = my_parse_bless(item_perl, MYPARSE_ITEM_CLASS);

	if (lex->orig_sql_command == SQLCOM_SHOW_FIELDS) {
		TABLE_LIST * table_list1 = (TABLE_LIST*) select_lex->table_list.first;
		SELECT_LEX * select_lex2 = table_list1->schema_select_lex;
		TABLE_LIST * table_list2 = (TABLE_LIST*) select_lex2->table_list.first;

		my_parse_set_array( item_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "TABLE_ITEM", MYPARSE_ARRAY_STRING);
		my_parse_set_array( item_perl, MYPARSE_ITEM_TABLE_NAME, (void *) table_list2->table_name, MYPARSE_ARRAY_STRING);
		my_parse_set_array( item_perl, MYPARSE_ITEM_DB_NAME, (void *) table_list2->db, MYPARSE_ARRAY_STRING);
	} else if (
		(lex->orig_sql_command == SQLCOM_SHOW_TABLES) ||
		(lex->orig_sql_command == SQLCOM_SHOW_TABLE_STATUS) ||
		(lex->sql_command == SQLCOM_CHANGE_DB)
	) {
		my_parse_set_array( item_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "DATABASE_ITEM", MYPARSE_ARRAY_STRING);
		my_parse_set_array( item_perl, MYPARSE_ITEM_DB_NAME, (void *) select_lex->db, MYPARSE_ARRAY_STRING);
	}

	return item_perl_ref;
}


perl_object * my_parse_item(THD * thd, Item * item) {

	item->fixed = 1;

	perl_object * perl_item = my_parse_create_array();
	perl_object * perl_item_ref = my_parse_bless(perl_item, MYPARSE_ITEM_CLASS);


	char item_type[255];
	my_parse_Type((int) item->type(), item_type);
	my_parse_set_array( perl_item, MYPARSE_ITEM_ITEM_TYPE, item_type, MYPARSE_ARRAY_STRING);
	
	char item_value_str[255];
	void * item_value_ref = NULL;
	size_t item_value_len = 0;
	perl_object * args_perl = my_parse_create_array();
	bool has_args = 0;

	if ((item->name) && (item->is_autogenerated_name == FALSE)) {	
		my_parse_set_array( perl_item, MYPARSE_ITEM_ALIAS, (void *) item->name, MYPARSE_ARRAY_STRING);
	}

	if (
		(item->type() == Item::DECIMAL_ITEM)
	) {
		String * string = new (thd->mem_root) String;
		String * value_str = item->val_str(string);
		item_value_ref = (void *) value_str->ptr();
	} else if  (
		(item->type() == Item::STRING_ITEM) ||
		(item->type() == Item::VARBIN_ITEM)
	) {
		CHARSET_INFO * charset = item->collation.collation;
		if (charset) {
			if (charset != thd->charset()) {
				my_parse_set_array( perl_item, MYPARSE_ITEM_CHARSET, (void *) charset->csname, MYPARSE_ARRAY_STRING);
			}
		}
		item_value_len = item->str_value.length();
		item_value_ref = (void *) item->str_value.ptr();
	} else if (item->type() == Item::INT_ITEM) {
		snprintf( item_value_str, 255, "%llu", item->val_int());
		item_value_ref = (void *) item_value_str;
	} else if (item->type() == Item::REAL_ITEM) {
		snprintf( item_value_str, 255, "%.20f", item->val_real());
		item_value_ref = (void *) item_value_str;
	} else if (
		(item->type() == Item::FIELD_ITEM) ||
		(item->type() == Item::REF_ITEM) ||
		(item->type() == Item::DEFAULT_VALUE_ITEM)
	) {
		Item_field * field;
			
		if (item->type() == Item::DEFAULT_VALUE_ITEM) { 
			Item_default_value * field1 = (Item_default_value *) item;
			field = (Item_field *) field1->arg;
		} else {
			field = (Item_field *) item;
		}

		if (field) {
			if (field->db_name) {
				my_parse_set_array( perl_item, MYPARSE_ITEM_DB_NAME, (void *) field->db_name, MYPARSE_ARRAY_STRING);
			}

			if (field->table_name) {
				my_parse_set_array( perl_item, MYPARSE_ITEM_TABLE_NAME, (void *) field->table_name, MYPARSE_ARRAY_STRING);
			}

			if (field->field_name) {
				my_parse_set_array( perl_item, MYPARSE_ITEM_FIELD_NAME, (void *) field->field_name, MYPARSE_ARRAY_STRING);
			}
		}
	} else if (item->type() == Item::ROW_ITEM) {
		Item_row * item_row = (Item_row *) item;
		int arg_count = item_row->arg_count;
		Item **arg = item_row->items;
		Item **arg_end = arg + arg_count;
		for (; arg != arg_end; arg++) {
			has_args = 1;
			Item *arg_item = *arg;
			perl_object * arg_perl = my_parse_item (thd, arg_item);
			my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, arg_perl, MYPARSE_ARRAY_REF);
		}
	} else if (
		(item->type() == Item::COND_ITEM) ||
		(item->type() == Item::FUNC_ITEM)
	) {

		char func_type[255];
		char func_name[255];

		Item_cond * cond = (Item_cond *) item;

		my_parse_Functype( cond->functype(), func_type);
		strcpy(func_name, cond->func_name());

		my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_TYPE, func_type, MYPARSE_ARRAY_STRING);
		my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, func_name, MYPARSE_ARRAY_STRING);

		if (
			(item->type() == Item::COND_ITEM) ||
			((item->type() == Item::FUNC_ITEM) && (cond->functype() == Item_func::COND_XOR_FUNC))
		) {
			List_iterator_fast<Item> li(*((Item_cond *) item)->argument_list());
			Item *sub_item;
			while ((sub_item = li++)) {
				has_args = 1;
				perl_object * argument_perl = my_parse_item(thd, sub_item);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, argument_perl, MYPARSE_ARRAY_REF);
			}
		}
		
		if (item->type() == Item::FUNC_ITEM) {

			if (
				!strcmp(func_name, "set_user_var") ||
				!strcmp(func_name,"get_user_var")
			) {
				has_args = 1;
				perl_object * var_param_perl = my_parse_create_array();
				perl_object * var_param_perl_ref = my_parse_bless(var_param_perl, MYPARSE_ITEM_CLASS);

				LEX_STRING var_name;

				if (!strcmp(func_name, "set_user_var")) {
					Item_func_set_user_var * set_user_var = (Item_func_set_user_var *) item;
					var_name = set_user_var->name;
				} else {
					Item_func_get_user_var * get_user_var = (Item_func_get_user_var *) item;
					var_name = get_user_var->name;
				}

				my_parse_set_array( var_param_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "USER_VAR_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( var_param_perl, MYPARSE_ITEM_VAR_NAME, var_name.str, MYPARSE_ARRAY_STRING);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, var_param_perl_ref, MYPARSE_ARRAY_REF);
			} else if (!strcmp(func_name, "get_system_var")) {
				has_args = 1;
				perl_object * var_param_perl = my_parse_create_array();
				perl_object * var_param_perl_ref = my_parse_bless(var_param_perl, MYPARSE_ITEM_CLASS);

				Item_func_get_system_var * get_system_var = (Item_func_get_system_var *) item;

				LEX_STRING component = get_system_var->component;
				if (component.str) {
					my_parse_set_array( var_param_perl, MYPARSE_ITEM_VAR_COMPONENT, component.str, MYPARSE_ARRAY_STRING);
				}

				switch (get_system_var->var_type) {
					case OPT_DEFAULT:
						my_parse_set_array( var_param_perl, MYPARSE_ITEM_VAR_TYPE, (void *) "OPT_DEFAULT", MYPARSE_ARRAY_STRING);
						break;
					case OPT_SESSION:
						my_parse_set_array( var_param_perl, MYPARSE_ITEM_VAR_TYPE, (void *) "OPT_SESSION", MYPARSE_ARRAY_STRING);
						break;
					case OPT_GLOBAL:
						my_parse_set_array( var_param_perl, MYPARSE_ITEM_VAR_TYPE, (void *) "OPT_GLOBAL", MYPARSE_ARRAY_STRING);
				}

				sys_var * var = get_system_var->var;
		
				if (var->name) {
					my_parse_set_array( var_param_perl, MYPARSE_ITEM_VAR_NAME, (void *) var->name, MYPARSE_ARRAY_STRING);
				}

				my_parse_set_array( var_param_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "SYSTEM_VAR_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, var_param_perl_ref, MYPARSE_ARRAY_REF);




			} else if (
				!strcmp(func_name, "extract") ||
				!strcmp(func_name, "timestampdiff")
			) {
				has_args = 1;
				char interval_type[255];
			
				if (!strcmp(func_name, "extract")) {
					Item_extract * extract = (Item_extract *) item;
					my_parse_interval_type(extract->int_type, interval_type);
				} else if (!strcmp(func_name, "timestampdiff")) {
					Item_func_timestamp_diff * timestamp_diff = (Item_func_timestamp_diff *) item;
					my_parse_interval_type(timestamp_diff->int_type, interval_type);
				}

				perl_object * interval_perl = my_parse_create_array();
				perl_object * interval_perl_ref = my_parse_bless(interval_perl, MYPARSE_ITEM_CLASS);
				my_parse_set_array( interval_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "INTERVAL_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( interval_perl, MYPARSE_ITEM_INTERVAL, interval_type, MYPARSE_ARRAY_STRING);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, interval_perl_ref, MYPARSE_ARRAY_REF);
			} else if (cond->functype() == Item_func::IN_FUNC) {
				Item_func_opt_neg * opt_neg = (Item_func_opt_neg *) item;
				if (opt_neg->negated) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "NOT_IN_FUNC", MYPARSE_ARRAY_STRING);
				}
			} else if (cond->functype() == Item_func::BETWEEN) {
				Item_func_opt_neg * opt_neg = (Item_func_opt_neg *) item;
				if (opt_neg->negated) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "NOT_BETWEEN", MYPARSE_ARRAY_STRING);
				}
			} else if (!strcmp(func_name, "benchmark")) {
				Item_func_benchmark * func_benchmark = (Item_func_benchmark *) item;
				perl_object * count_perl = my_parse_create_array();
				perl_object * count_perl_ref = my_parse_bless(count_perl, MYPARSE_ITEM_CLASS);
				my_parse_set_array( count_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "INT_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( count_perl, MYPARSE_ITEM_VALUE, &func_benchmark->loop_count, MYPARSE_ARRAY_LONG);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, count_perl_ref, MYPARSE_ARRAY_REF);
			}

			Item_func * func = (Item_func *) item;

			if (func->arg_count) {
				Item **arg = func->arguments();
				Item **arg_end = arg + func->arg_count;

				has_args = 1;

				if (!strcmp(func_name, "locate")) {
					perl_object * arg2_perl = my_parse_item(thd, (Item *) *arg++);
					my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, arg2_perl, MYPARSE_ARRAY_REF);
					perl_object * arg1_perl = my_parse_item(thd, (Item *) *arg++);
					my_parse_set_array( args_perl, MYPARSE_ARRAY_PREPEND, arg1_perl, MYPARSE_ARRAY_REF);

					if (func->arg_count == 3) {
						perl_object * arg3_perl = my_parse_item(thd, (Item *) *arg);
						my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, arg3_perl, MYPARSE_ARRAY_REF);
					}
				} else {
					for (;arg != arg_end; arg++) {
						perl_object * argument_perl = my_parse_item(thd, (Item *) *arg );
						my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, argument_perl, MYPARSE_ARRAY_REF);
					}
				}
			}

			if (!strcmp(func_name, "date_add_interval")) {
				char interval_type[255];

				Item_date_add_interval * date_add_interval = (Item_date_add_interval *) item;
				if (date_add_interval->date_sub_interval) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "date_sub_interval", MYPARSE_ARRAY_STRING);
				}
				my_parse_interval_type(date_add_interval->int_type, interval_type);

				perl_object * interval_perl = my_parse_create_array();
				perl_object * interval_perl_ref = my_parse_bless(interval_perl, MYPARSE_ITEM_CLASS);
				my_parse_set_array( interval_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "INTERVAL_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( interval_perl, MYPARSE_ITEM_INTERVAL, interval_type, MYPARSE_ARRAY_STRING);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, interval_perl_ref, MYPARSE_ARRAY_REF);
			} else if (!strcmp(func_name, "cast_as_char")) {
				Item_char_typecast * char_typecast = (Item_char_typecast *) item;
				if (char_typecast->cast_length > 0) {
					perl_object * length_perl = my_parse_create_array();
					perl_object * length_perl_ref = my_parse_bless(length_perl, MYPARSE_ITEM_CLASS);
					my_parse_set_array( length_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "INT_ITEM", MYPARSE_ARRAY_STRING);
/*					my_parse_set_array( length_perl, MYPARSE_ITEM_VALUE, lex->length, MYPARSE_ARRAY_STRING);	*/
					my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, length_perl_ref, MYPARSE_ARRAY_REF);
				}
				CHARSET_INFO * charset = char_typecast->cast_cs;
				if (charset == &my_charset_bin) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "cast_as_binary", MYPARSE_ARRAY_STRING);
				}
	
			} else if (!strcmp(func_name, "convert")) {
				Item_func_conv_charset * func_conv = (Item_func_conv_charset *) item;
				if (func_conv->conv_charset) {
					CHARSET_INFO * charset = func_conv->conv_charset;
					perl_object * charset_perl = my_parse_create_array();
					perl_object * charset_perl_ref = my_parse_bless(charset_perl, MYPARSE_ITEM_CLASS);
					my_parse_set_array( charset_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "CHARSET_ITEM", MYPARSE_ARRAY_STRING);
					my_parse_set_array( charset_perl, MYPARSE_ITEM_CHARSET, (void *) charset->csname, MYPARSE_ARRAY_STRING);
					my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, charset_perl_ref, MYPARSE_ARRAY_REF);
				}
			} else if (!strcmp(func_name,"format")) {
				Item_func_format * format = (Item_func_format *) func;
				perl_object * var_perl = my_parse_create_array();
				perl_object * var_perl_ref = my_parse_bless( var_perl, MYPARSE_ITEM_CLASS);
					
				my_parse_set_array( var_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "INT_ITEM", MYPARSE_ARRAY_STRING);
				my_parse_set_array( var_perl, MYPARSE_ITEM_VALUE, (void *) &format->decimals, MYPARSE_ARRAY_INT);
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, var_perl_ref, MYPARSE_ARRAY_REF);
			} else if (cond->functype() == Item_func::LIKE_FUNC) {
				Item_func_like * like = (Item_func_like *) item;
				if (like->escape_used_in_parsing) {
					perl_object * escape_perl = my_parse_item(thd, like->escape_item);
					my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, escape_perl, MYPARSE_ARRAY_REF);
				}
			} else if (!strcmp(func_name,"case")) {
				Item_func_case * func_case = (Item_func_case *) item;
				if (func_case->first_expr_num > -1) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "case_switch", MYPARSE_ARRAY_STRING);
				}
			}
		}
	} else if (item->type() == Item::SUM_FUNC_ITEM) {
		Item_sum * sum = (Item_sum *) item;

		char sum_func_type[255];
		char sum_func_name[255];

		strcpy(sum_func_name, sum->func_name());
		my_parse_Sumfunctype( sum->sum_func(), sum_func_type);

		my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_TYPE, sum_func_type, MYPARSE_ARRAY_STRING);
		my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, sum_func_name, MYPARSE_ARRAY_STRING);

		if (sum->arg_count) {
			Item **arg, **arg_end;
			has_args = 1;
			for (arg = sum->args, arg_end = sum->args + sum->arg_count; arg != arg_end; arg++) {
				has_args = 1;
				perl_object * argument_perl = my_parse_item(thd, (Item *) *arg );
				my_parse_set_array( args_perl, MYPARSE_ARRAY_APPEND, argument_perl, MYPARSE_ARRAY_REF);
			}
		}
		
		if (!strcmp(sum_func_type, "STD_FUNC")) {
			Item_sum_std * std_item = (Item_sum_std *) item;
			if (std_item->sample == 1) {
				my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "stddev_samp(", MYPARSE_ARRAY_STRING);
			} else {
				my_parse_set_array( perl_item, MYPARSE_ITEM_FUNC_NAME, (void *) "stddev_pop(", MYPARSE_ARRAY_STRING);
			}
		}

	} else if (item->type() == Item::SUBSELECT_ITEM) {
		Item_subselect * subselect_item = (Item_subselect *) item;

		if (
			(subselect_item->substype() == Item_subselect::IN_SUBS) ||
			(subselect_item->substype() == Item_subselect::ALL_SUBS) ||
			(subselect_item->substype() == Item_subselect::ANY_SUBS)
		) {
			Item_in_subselect * in_subselect_item = (Item_in_subselect *) subselect_item;
			perl_object * left_arg_perl = my_parse_item(thd, (Item *) in_subselect_item->left_expr);

			my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_EXPR, left_arg_perl, MYPARSE_ARRAY_REF);

			if (subselect_item->substype() == Item_subselect::IN_SUBS) { 
				my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_TYPE, (void *) "IN_SUBS", MYPARSE_ARRAY_STRING);
			} else {
				Item_allany_subselect * allany_subselect_item = (Item_allany_subselect *) subselect_item;
				Comp_creator * func = allany_subselect_item->func;
				if (func) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_COND, (void *) func->symbol(allany_subselect_item->all), MYPARSE_ARRAY_STRING);
				}

				if (subselect_item->substype() == Item_subselect::ALL_SUBS) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_TYPE, (void *) "ALL_SUBS", MYPARSE_ARRAY_STRING);			
				} else if (subselect_item->substype() == Item_subselect::ANY_SUBS) {
					my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_TYPE, (void *) "ANY_SUBS", MYPARSE_ARRAY_STRING);
				}
			}
		} else if (subselect_item->substype() == Item_subselect::EXISTS_SUBS) {
			my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_TYPE, (void *) "EXISTS_SUBS", MYPARSE_ARRAY_STRING);			
		} else if (subselect_item->substype() == Item_subselect::SINGLEROW_SUBS) {
			my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_TYPE, (void *) "SINGLEROW_SUBS", MYPARSE_ARRAY_STRING);			
		}

                st_select_lex_unit * unit = subselect_item->unit;
                SELECT_LEX *sl = unit->first_select();

		perl_object * subquery_perl = my_parse_inner(unit->thd, sl, 1);
		my_parse_set_array( perl_item, MYPARSE_ITEM_SUBSELECT_QUERY, subquery_perl, MYPARSE_ARRAY_REF);
	
	}

	if (has_args) {
		my_parse_set_array( perl_item, MYPARSE_ITEM_ARGUMENTS, args_perl, MYPARSE_ARRAY_REF);
	} else {
		my_parse_free_array( args_perl );
	}

	if (item_value_ref) {
		if (item_value_len) {
			/* If we know the length, we construct the perl string ourselves
				so that the length is reported correctly and any NULL
				characters inside the string do not terminate it
			*/
			perl_object * string_perl = my_parse_create_string( (char *) item_value_ref, item_value_len);
			my_parse_set_array( perl_item, MYPARSE_ITEM_VALUE, string_perl, MYPARSE_ARRAY_SV);
		} else {
			my_parse_set_array( perl_item, MYPARSE_ITEM_VALUE, item_value_ref, MYPARSE_ARRAY_STRING);
		}
	}

	return perl_item_ref;
}

int my_parse_init(int my_argc, char ** my_argv, char ** my_groups) {
 	return mysql_server_init(my_argc,my_argv,my_groups);
}

perl_object * my_parse_outer(perl_object * parser, char * db, char * query) {

	if (global_thd == NULL) {
		global_thd = (THD *) create_embedded_thd(0);
	}

	THD * thd = global_thd;
			
	alloc_query(thd, query, strlen(query) + 1);

	lex_start(thd);
	mysql_reset_thd_for_next_command(thd);

	Lex_input_stream lip(thd, query, strlen(query));
	thd->m_lip= &lip;
	lip.stmt_prepare_mode = 1;
	
	LEX * lex = thd->lex;

	thd->set_db(db, strlen(db));
	lex->select_lex.db = db;

	lex->wild = NULL;
	lex->select_lex.having = NULL;
	lex->select_lex.where = NULL;
	lex->select_lex.order_list.first = NULL;
	lex->select_lex.group_list.first = NULL;
/*	lex->select_lex.explicit_limit = NULL; */

/*	lex->stmt_prepare_mode = TRUE;	*/	/* Gone in 5.0.45 */
	thd->command = COM_STMT_PREPARE;
	int error = MYSQLparse((void *)thd) || thd->is_fatal_error || thd->net.report_error;

	perl_object * query_perl_ref;

	if (error) {
		perl_object * query_perl = my_parse_create_array();
		query_perl_ref = my_parse_bless(query_perl, MYPARSE_QUERY_CLASS);

		my_parse_set_array( query_perl, MYPARSE_COMMAND, (void *) "SQLCOM_ERROR", MYPARSE_ARRAY_STRING);
	
		my_parse_set_array( query_perl, MYPARSE_ERRNO, &thd->net.last_errno, MYPARSE_ARRAY_LONG);
		my_parse_set_array( query_perl, MYPARSE_ERRSTR, thd->net.last_error, MYPARSE_ARRAY_STRING);

		char errno_as_string[255];
		my_parse_errno(thd->net.last_errno, errno_as_string);
		my_parse_set_array( query_perl, MYPARSE_ERROR, (void *) errno_as_string, MYPARSE_ARRAY_STRING);

		my_parse_set_array( query_perl, MYPARSE_SQLSTATE, (void *) mysql_errno_to_sqlstate(thd->net.last_errno), MYPARSE_ARRAY_STRING);
	} else {
		query_perl_ref = my_parse_inner( thd, &lex->select_lex, 0);
	}

/*	query_cache_abort(&thd->net);	*/
	lex->unit.cleanup();
	close_thread_tables(thd);
	thd->end_statement();
	thd->cleanup_after_query();
	lex_end(lex);
	thd->packet.shrink(thd->variables.net_buffer_length); // Reclaim some memory
	free_root(thd->mem_root,MYF(MY_KEEP_PREALLOC));

	return query_perl_ref;
}

perl_object * my_parse_order(THD * thd, st_select_lex * select_lex, ORDER * start_order) {

	perl_object * orders_perl = my_parse_create_array();

	ORDER * order;

	for (order = start_order ; order ; order = order->next) {
		perl_object * order_perl = my_parse_item(thd, (Item_cond *) *order->item);
		my_parse_set_array( orders_perl, MYPARSE_ARRAY_APPEND, order_perl, MYPARSE_ARRAY_REF);

		if (order->asc) {
			my_parse_set_array( order_perl, MYPARSE_ITEM_DIR, (void *) "ASC", MYPARSE_ARRAY_STRING);
		} else {
			my_parse_set_array( order_perl, MYPARSE_ITEM_DIR, (void *) "DESC", MYPARSE_ARRAY_STRING);
		}
	}
	return orders_perl;
}

perl_object * my_parse_inner(THD * thd, st_select_lex * select_lex, bool in_subquery) {

	void * query_perl = my_parse_create_array();
	void * query_perl_ref = my_parse_bless(query_perl, MYPARSE_QUERY_CLASS);

	LEX * lex = thd->lex;

	perl_object * options_perl = my_parse_query_options( select_lex->options );
	my_parse_set_array( query_perl, MYPARSE_QUERY_OPTIONS, options_perl, MYPARSE_ARRAY_REF);

	if (!in_subquery) {
		if (lex->describe) {
			if (lex->describe & DESCRIBE_NORMAL) {
				my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "DESCRIBE_NORMAL", MYPARSE_ARRAY_STRING);
			}
			if (lex->describe & DESCRIBE_EXTENDED) {
				my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "DESCRIBE_EXTENDED", MYPARSE_ARRAY_STRING);
			}
		}

		if (lex->ignore) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "IGNORE", MYPARSE_ARRAY_STRING);
		}

		if (lex->lock_option == TL_READ_HIGH_PRIORITY) {
			char lock_option[255];
			my_parse_thr_lock_type( lex->lock_option, lock_option);
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) lock_option, MYPARSE_ARRAY_STRING);
		}
	} else {
		lex->sql_command = SQLCOM_SELECT;
		lex->orig_sql_command = SQLCOM_END;
	}

	char sql_command[255];
	char orig_sql_command[255];

	my_parse_enum_sql_command(lex->sql_command, sql_command);
	my_parse_enum_sql_command(lex->orig_sql_command, orig_sql_command);

	my_parse_set_array( query_perl, MYPARSE_COMMAND, sql_command, MYPARSE_ARRAY_STRING);
	my_parse_set_array( query_perl, MYPARSE_ORIG_COMMAND, orig_sql_command, MYPARSE_ARRAY_STRING);

	perl_object * items_perl;

	if (
		(lex->sql_command == SQLCOM_SAVEPOINT) ||
		(lex->sql_command == SQLCOM_ROLLBACK_TO_SAVEPOINT) ||
		(lex->sql_command == SQLCOM_RELEASE_SAVEPOINT)
	) {
		my_parse_set_array( query_perl, MYPARSE_SAVEPOINT, (void *) lex->ident.str, MYPARSE_ARRAY_STRING);
	}

	if (
		(lex->sql_command == SQLCOM_BEGIN) &&
		(lex->start_transaction_opt == MYSQL_START_TRANS_OPT_WITH_CONS_SNAPSHOT)
	) {
		my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "WITH_CONSISTENT_SNAPSHOT", MYPARSE_ARRAY_STRING);
	}

	if (
		(lex->sql_command == SQLCOM_COMMIT) ||
		(lex->sql_command == SQLCOM_ROLLBACK)
	) {
		if (lex->tx_chain == 0) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "NO_CHAIN", MYPARSE_ARRAY_STRING);
		} else if (lex->tx_chain == 1) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "CHAIN", MYPARSE_ARRAY_STRING);
		}

		if (lex->tx_release == 0) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "NO_RELEASE", MYPARSE_ARRAY_STRING);
		} else if (lex->tx_release == 1) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "RELEASE", MYPARSE_ARRAY_STRING);
		}
	}

	if (
		(lex->sql_command == SQLCOM_CREATE_DB) ||
		(lex->sql_command == SQLCOM_DROP_DB)
	) {
		perl_object * database_perl = my_parse_create_array();
		perl_object * database_perl_ref = my_parse_bless(database_perl, MYPARSE_ITEM_CLASS);
		my_parse_set_array( database_perl, MYPARSE_ITEM_ITEM_TYPE, (void *) "DATABASE_ITEM", MYPARSE_ARRAY_STRING);
		my_parse_set_array( database_perl, MYPARSE_ITEM_DB_NAME, (void *) lex->name, MYPARSE_ARRAY_STRING);
		my_parse_set_array( query_perl, MYPARSE_SCHEMA_SELECT, database_perl_ref, MYPARSE_ARRAY_REF);
	}

	if ((
		(lex->sql_command == SQLCOM_DROP_DB) ||
		(lex->sql_command == SQLCOM_DROP_TABLE)
	) && lex->drop_if_exists) {
		my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "DROP_IF_EXISTS", MYPARSE_ARRAY_STRING);
	}

	if (
		(lex->sql_command == SQLCOM_CREATE_DB) &&
		(lex->create_info.options == HA_LEX_CREATE_IF_NOT_EXISTS)
	) {
		my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "CREATE_IF_NOT_EXISTS", MYPARSE_ARRAY_STRING);
	}

	if (lex->sql_command == SQLCOM_DROP_TABLE) {
		if (lex->drop_mode == DROP_RESTRICT) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "DROP_RESTRICT", MYPARSE_ARRAY_STRING);
		} else if (lex->drop_mode == DROP_CASCADE) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "DROP_CASCADE", MYPARSE_ARRAY_STRING);
		}

		if (lex->drop_temporary) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "DROP_TEMPORARY", MYPARSE_ARRAY_STRING);
		}
	}

	if (
		(lex->sql_command == SQLCOM_SELECT) &&
		(lex->safe_to_cache_query == 0)
	) {
		my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "SQL_NO_CACHE", MYPARSE_ARRAY_STRING);
	}


	switch (lex->sql_command) {
		case SQLCOM_SELECT:
		case SQLCOM_INSERT_SELECT:
		case SQLCOM_REPLACE_SELECT:
			items_perl = my_parse_list_items(thd, query_perl, select_lex->item_list);
			my_parse_set_array( query_perl, MYPARSE_SELECT_ITEMS, items_perl, MYPARSE_ARRAY_REF);
			break;
		case SQLCOM_UPDATE:
		case SQLCOM_UPDATE_MULTI:
			items_perl = my_parse_list_items(thd, query_perl, select_lex->item_list);
			my_parse_set_array( query_perl, MYPARSE_UPDATE_VALUES, items_perl, MYPARSE_ARRAY_REF);
			break;
		default:
			break;
	};

	/* List of INSERT/REPLACEMENT values */

	perl_object * fields_perl;

	switch (lex->sql_command) {
		case SQLCOM_INSERT:
		case SQLCOM_REPLACE:
		case SQLCOM_INSERT_SELECT:
		case SQLCOM_REPLACE_SELECT:
			fields_perl = my_parse_list_items(thd, query_perl, lex->field_list);
			my_parse_set_array( query_perl, MYPARSE_INSERT_FIELDS, fields_perl, MYPARSE_ARRAY_REF);
			break;
		case SQLCOM_UPDATE:
		case SQLCOM_UPDATE_MULTI:
			fields_perl = my_parse_list_items(thd, query_perl, select_lex->item_list);
			my_parse_set_array( query_perl, MYPARSE_UPDATE_FIELDS, fields_perl, MYPARSE_ARRAY_REF);
/*		case SQLCOM_SET_OPTION:
			fields_perl = my_parse_create_array();
			List_iterator_fast<set_var_base> it(&lex->var_list);
			set_var_base * var_base;
			while ((var=it++)) {
				set_var * var = (set_var *) var_base;
				perl_object * field_perl = my_parse_create_array();
				perl_object * field_perl_ref = my_parse_bless(field_perl, MYPARSE_ITEM_CLASS);
			}

*/
		default:
			break;
	}

	if ((!in_subquery) && (lex->value_list.elements > 0)) {
		perl_object * values_perl = my_parse_list_items(thd, query_perl, lex->value_list);
		my_parse_set_array( query_perl, MYPARSE_UPDATE_VALUES, values_perl, MYPARSE_ARRAY_REF);
	}

	if (
		(lex->sql_command == SQLCOM_INSERT) ||
		(lex->sql_command == SQLCOM_INSERT_SELECT) ||
		(lex->sql_command == SQLCOM_REPLACE) ||
		(lex->sql_command == SQLCOM_REPLACE_SELECT) ||
		(lex->sql_command == SQLCOM_DO)
	) {

		if (lex->insert_list) {
			perl_object * all_values_perl = my_parse_create_array();
			perl_object * row_values_perl = my_parse_list_items(thd, query_perl, *lex->insert_list);
			my_parse_set_array( all_values_perl, MYPARSE_ARRAY_APPEND, row_values_perl, MYPARSE_ARRAY_REF);
			if (lex->sql_command == SQLCOM_DO) {
				my_parse_set_array( query_perl, MYPARSE_SELECT_ITEMS, all_values_perl, MYPARSE_ARRAY_REF);
			} else {
				my_parse_set_array( query_perl, MYPARSE_INSERT_VALUES, all_values_perl, MYPARSE_ARRAY_REF);
			}
		}

		if (lex->many_values.elements > 0) {
			perl_object * all_values_perl = my_parse_create_array();
			List_iterator_fast<List_item> iterator_lists(lex->many_values);
			List_item *list_item;
			while ((list_item = iterator_lists++)) {
				perl_object * row_values_perl = my_parse_list_items(thd, query_perl, *list_item);
				my_parse_set_array( all_values_perl, MYPARSE_ARRAY_APPEND, row_values_perl, MYPARSE_ARRAY_REF);
			}
			my_parse_set_array( query_perl, MYPARSE_INSERT_VALUES, all_values_perl, MYPARSE_ARRAY_REF);
		}

		if (lex->update_list.elements > 0) {
			perl_object * updates_perl = my_parse_list_items(thd, query_perl, lex->update_list);
			my_parse_set_array( query_perl, MYPARSE_UPDATE_FIELDS, updates_perl, MYPARSE_ARRAY_REF);
		}
	}

	if (select_lex->table_list.elements > 0) {
		perl_object * tables_perl = NULL;

		switch (lex->sql_command) {
			case SQLCOM_SELECT:
			case SQLCOM_UPDATE_MULTI:
			case SQLCOM_INSERT_SELECT:
			case SQLCOM_REPLACE_SELECT:
				tables_perl = my_parse_create_array();

				if (select_lex->top_join_list.elements > 0) {
					perl_object * select_tables_perl = my_parse_tables_obj(thd, select_lex, query_perl, &select_lex->top_join_list );
					my_parse_set_array( tables_perl, MYPARSE_ARRAY_APPEND, select_tables_perl, MYPARSE_ARRAY_REF);
				}
	
				if (
					(lex->sql_command == SQLCOM_INSERT_SELECT) ||
					(lex->sql_command == SQLCOM_REPLACE_SELECT)
				) {
			                TABLE_LIST * insert_table = (TABLE_LIST *) select_lex->table_list.first;
					perl_object * table_perl = my_parse_table(thd, select_lex, query_perl, query_perl, insert_table);
					my_parse_set_array( tables_perl, MYPARSE_ARRAY_PREPEND, table_perl, MYPARSE_ARRAY_REF);
				}

				break;
			default:
				tables_perl = my_parse_tables_list(thd, select_lex, query_perl, (TABLE_LIST *) select_lex->table_list.first );

		}

		my_parse_set_array( query_perl, MYPARSE_TABLES, tables_perl, MYPARSE_ARRAY_REF);
	}

	/* This is used to obtain the list of the tables on which multiple-table DELETE actually operates */

	if (lex->sql_command == SQLCOM_DELETE_MULTI) {
		TABLE_LIST * delete_tables = NULL;
		perl_object * delete_tables_perl = my_parse_create_array();

		TABLE_LIST * start_delete_table = (TABLE_LIST *) lex->auxiliary_table_list.first;
		for (delete_tables = start_delete_table; delete_tables; delete_tables = delete_tables->next_global) {
			perl_object * delete_table_perl = my_parse_table(thd, select_lex, query_perl, query_perl, delete_tables);
			my_parse_set_array( delete_tables_perl, MYPARSE_ARRAY_APPEND, delete_table_perl, MYPARSE_ARRAY_REF);
		}

		my_parse_set_array( query_perl, MYPARSE_DELETE_TABLES, delete_tables_perl, MYPARSE_ARRAY_REF);
	}

	COND * start_where = (COND *) select_lex->where;
	
	if (start_where) {
		perl_object * where_perl = my_parse_item(thd, (Item_cond *) start_where);
		my_parse_set_array( query_perl, MYPARSE_WHERE, where_perl, MYPARSE_ARRAY_REF);
	}

	if (
		(lex->orig_sql_command == SQLCOM_SHOW_TABLES) ||
		(lex->orig_sql_command == SQLCOM_SHOW_TABLE_STATUS) ||
		(lex->orig_sql_command == SQLCOM_SHOW_FIELDS) ||
		(lex->orig_sql_command == SQLCOM_SHOW_DATABASES) ||
		(lex->sql_command == SQLCOM_CHANGE_DB)
	) {
		perl_object * schema_perl = my_parse_schema_select(lex, select_lex);
		my_parse_set_array( query_perl, MYPARSE_SCHEMA_SELECT, schema_perl, MYPARSE_ARRAY_REF);
	}
	
	if ((!in_subquery) && (lex->wild)) {
		my_parse_set_array( query_perl, MYPARSE_WILD, (void *) lex->wild->ptr(), MYPARSE_ARRAY_STRING);
	}

	if (select_lex->having) {
		perl_object * having_perl = my_parse_item(thd, (Item_cond *) select_lex->having);
		my_parse_set_array( query_perl, MYPARSE_HAVING, having_perl, MYPARSE_ARRAY_REF);
	}

	if (select_lex->order_list.first) {
		perl_object * orders_perl = my_parse_order(thd, select_lex, (ORDER *) select_lex->order_list.first);
		my_parse_set_array( query_perl, MYPARSE_ORDER, orders_perl, MYPARSE_ARRAY_REF);
	}

	if (select_lex->group_list.first) {
		perl_object * groups_perl = my_parse_order(thd, select_lex, (ORDER *) select_lex->group_list.first);
		my_parse_set_array( query_perl, MYPARSE_GROUP, groups_perl, MYPARSE_ARRAY_REF);

		if (select_lex->olap == CUBE_TYPE) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "WITH_CUBE", MYPARSE_ARRAY_STRING);
		} else if (select_lex->olap == ROLLUP_TYPE) {
			my_parse_set_array( options_perl, MYPARSE_ARRAY_APPEND, (void *) "WITH_ROLLUP", MYPARSE_ARRAY_STRING);
		}
	}

	if (select_lex->explicit_limit) {
		perl_object * limit_perl = my_parse_create_array();
		my_parse_set_array( query_perl, MYPARSE_LIMIT, limit_perl, MYPARSE_ARRAY_REF);

		if (select_lex->select_limit) {
			my_parse_set_array( limit_perl, MYPARSE_LIMIT_SELECT, my_parse_item(thd, select_lex->select_limit), MYPARSE_ARRAY_REF);
		}

		if (select_lex->offset_limit) {
			my_parse_set_array( limit_perl, MYPARSE_LIMIT_OFFSET, my_parse_item(thd, select_lex->offset_limit), MYPARSE_ARRAY_REF);
		}
	}

	return query_perl_ref;
}
