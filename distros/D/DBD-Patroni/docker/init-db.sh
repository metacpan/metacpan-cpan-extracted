#!/bin/bash
set -e

echo "=== init-db.sh starting ==="

# Create test user and database
echo "Creating test user and database..."
psql -U postgres <<-EOSQL
    CREATE USER testuser WITH PASSWORD 'testpass';
    CREATE DATABASE testdb OWNER testuser;
EOSQL

echo "=== User and database created ==="

# Create test tables
psql -U postgres -d testdb <<-EOSQL
    CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
    );
    GRANT ALL PRIVILEGES ON TABLE users TO testuser;
    GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO testuser;

    CREATE TABLE logs (
        id SERIAL PRIMARY KEY,
        message TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    );
    GRANT ALL PRIVILEGES ON TABLE logs TO testuser;
    GRANT USAGE, SELECT ON SEQUENCE logs_id_seq TO testuser;
EOSQL
