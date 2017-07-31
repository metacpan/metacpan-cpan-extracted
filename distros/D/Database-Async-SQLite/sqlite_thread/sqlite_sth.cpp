#include <iostream>
#include <unordered_map>

#include "sqlite_sth.h"
#include "sqlite_dbh.h"
#include "sqlite_queue.h"

#include "sqlite3.h"

sqlite_sth::sqlite_sth(
	sqlite_dbh &dbh,
	const std::string &sql
):dbh_{ dbh },
  sql_{ sql }
{
	auto code = sqlite3_prepare_v2(
		dbh_.db(),
		sql_.data(),
		1 + sql_.size(),
		&stmt_,
		nullptr
	);
	if(code != SQLITE_OK) {
        auto err = std::string {
            "Failed to prepare query "
        } + sql + std::string {
            " - "
        } + std::string {
            sqlite3_errmsg(dbh_.db())
        }; 
		sqlite3_finalize(stmt_);
		throw std::runtime_error(err);
	}
	count_ = sqlite3_column_count(stmt_);
	for(int i = 0; i < count_; ++i) {
		column_names_.emplace_back(
			sqlite3_column_name(stmt_, i)
		);
	}
}

sqlite_sth::~sqlite_sth()
{
	sqlite3_finalize(stmt_);
}

void
sqlite_sth::step()
{
	auto *self = this;
	dbh_.push([self] {
		if(self->stmt_ == nullptr) {
			throw std::logic_error("did not have valid sth");
		}
		auto code = sqlite3_step(self->stmt_);
		switch(code) {
		case SQLITE_OK:
			std::cerr << self->stmt_ << " - OK\n";
			break;
		case SQLITE_BUSY:
			std::cerr << self->stmt_ << " - busy\n";
			break;
		case SQLITE_DONE:
			std::cerr << self->stmt_ << " - done\n";
			break;
		case SQLITE_ROW: {
			std::cerr << self->stmt_ << " - row\n";
			auto start = std::chrono::steady_clock::now();
			{
				std::unordered_map<std::string, std::string> row;
				for(int i = 0; i < self->count_; ++i) {
					const char *data = reinterpret_cast<const char *>(sqlite3_column_text(self->stmt_, i));
					std::string::size_type size = sqlite3_column_bytes(self->stmt_, i);
					std::string s { data, size };
					// std::string k { sqlite3_column_name(self->stmt_, i) };
					// std::cerr << k << " (" << i << ") = " << s << std::endl;
					row[self->column_names_[i]] = s;
				}
			}
			auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(
				std::chrono::steady_clock::now() - start
			);
			std::cerr << "This row took " << duration.count() << "ns\n";
			break;
		 }
		case SQLITE_ERROR:
			std::cerr << self->stmt_ << " - error\n";
			break;
		case SQLITE_MISUSE:
			std::cerr << self->stmt_ << " - misuse\n";
			break;
		default:
			std::cerr << "Unknown SQLite return code: " << code << std::endl;
			break;
		}
	});
}

