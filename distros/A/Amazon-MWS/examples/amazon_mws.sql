DROP TABLE IF EXISTS amazon_mws_jobs;
DROP TABLE IF EXISTS amazon_mws_feeds;
DROP TABLE IF EXISTS amazon_mws_products;

CREATE TABLE amazon_mws_jobs (
      amws_job_id VARCHAR(64) NOT NULL,
      shop_id VARCHAR(64) NOT NULL,
      task VARCHAR(64) NOT NULL,
      -- if complete one or those has to be set.
      aborted BOOLEAN NOT NULL DEFAULT FALSE,
      success BOOLEAN NOT NULL DEFAULT FALSE,
      last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (amws_job_id, shop_id)
); 

CREATE TABLE amazon_mws_feeds (
       amws_feed_pk SERIAL NOT NULL PRIMARY KEY,
       -- not strictly needed, but helpful anyway
       shop_id VARCHAR(64) NOT NULL,
       amws_job_id VARCHAR(64) NOT NULL REFERENCES amazon_mws_jobs(amws_job_id),
       feed_id VARCHAR(64) UNIQUE, -- populated when we get the id
       feed_name VARCHAR(255) NOT NULL,
       feed_file VARCHAR(255) NOT NULL UNIQUE,
       processing_complete BOOLEAN NOT NULL DEFAULT FALSE,
       aborted BOOLEAN NOT NULL DEFAULT FALSE,
       success BOOLEAN NOT NULL DEFAULT FALSE,
       errors TEXT,
       notes  TEXT,
       last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- table to keep track of the uploaded items

CREATE TABLE amazon_mws_products (
       -- don't enforce the sku format
       sku VARCHAR(255) NOT NULL,
       shop_id VARCHAR(64) NOT NULL,
       -- given that we just test for equality, don't enforce a type.
       -- So an epoch will do just fine, as it would be a random date,
       -- as long as the script sends consistent data
       timestamp_string VARCHAR(255) NOT NULL DEFAULT '0',
       status VARCHAR(32),
       -- this can be null
       amws_job_id VARCHAR(64) REFERENCES amazon_mws_jobs(amws_job_id),
       error_code integer NOT NULL DEFAULT '0',
       error_msg TEXT,
       listed_date DATETIME,
       -- our update
       last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
       PRIMARY KEY (sku, shop_id)
);

CREATE TABLE amazon_mws_orders (
       shop_id         VARCHAR(64) NOT NULL,
       amazon_order_id VARCHAR(64) NOT NULL,
       shop_order_id   VARCHAR(64) NOT NULL,
       amws_job_id     VARCHAR(64) REFERENCES amazon_mws_jobs(amws_job_id),
       error_code INTEGER NOT NULL DEFAULT 0,
       error_msg TEXT,
       confirmed BOOLEAN NOT NULL DEFAULT FALSE,
       last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
       PRIMARY KEY (shop_id, amazon_order_id)
);

ALTER TABLE amazon_mws_orders ADD COLUMN shipping_confirmation_job_id VARCHAR(64) REFERENCES amazon_mws_jobs(amws_job_id);
ALTER TABLE amazon_mws_orders ADD COLUMN shipping_confirmation_ok BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE amazon_mws_orders ADD COLUMN shipping_confirmation_error TEXT;
ALTER TABLE amazon_mws_jobs   ADD COLUMN job_started_epoch INTEGER;
ALTER TABLE amazon_mws_jobs   ADD COLUMN status VARCHAR(255);

-- 2015-01-29
ALTER TABLE amazon_mws_orders ADD COLUMN status VARCHAR(255);
ALTER TABLE amazon_mws_products ADD COLUMN warnings TEXT;

