# Basic functionality

* Send SQL query to server
* Return reuslts

Results as:

* hashref per row
* arrayref per row

# Transactions
# Queries
# Connection pools
# Master/slave
# Read-only, r/w

# Table
# View
# Database
# Schema
# User
# Index

## Database::Async

* pools

## Database::Async::Transaction

* commit
* rollback
* savepoint
* prepare_commit - two-phase commit, first step

## Database::Async::Transaction::Savepoint

## Database::Async::Row

* fields
* field('key')
* field($field)

## Database::Async::Field

## Database::Async::Connection

* is_tls
* is_readonly

* transactions
* statements

## Database::Async::Connection::Pool

* connections

## Database::Async::Statement


