#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_newSVpvn_flags
#include "ppport.h"

#ifdef __cplusplus
} /* extern "C" */
#endif

#include <sqlite_thread.h>
#include <sqlite_dbh.h>
#include <iostream>

// this causes me much sadness
using namespace std;

MODULE = Database::Async::SQLite          PACKAGE = Database::Async::SQLite

PROTOTYPES: DISABLE

sqlite_dbh *
sqlite_dbh::new(string name)

SV *
sqlite_dbh::filename()
	CODE:
		XSRETURN_PV(THIS->filename().data());

int
sqlite_dbh::eventfd()
	CODE:
		XSRETURN_IV(THIS->eventfd());

sqlite_sth *
sqlite_dbh::prepare(string sql)
	CODE:
		RETVAL = THIS->prepare(sql);
	OUTPUT:
		RETVAL

MODULE = Database::Async::SQLite          PACKAGE = Database::Async::SQLite::STH

#include <unordered_map>
#include <sqlite_sth.h>

void
sqlite_sth::step()
	CODE:
		THIS->step();

void
sqlite_sth::on_row()
	CODE:
		auto row_map = std::unordered_map<std::string, std::string>();
		HV *row = (HV *) sv_2mortal((SV *) newHV());
		for(const auto &item : row_map) {
			hv_store(
				row, // the hash
				item.first.data(), // key
				-(item.first.size() + 1), // key length including \0, negative to indicate UTF-8
				newSVpvn_utf8(
					(item.second.data()),
					(item.second.size() + 1),
					1
				), // value
				0
			);
		}

