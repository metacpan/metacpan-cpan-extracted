DROP TABLE IF EXISTS product_price_changes;

DROP TRIGGER IF EXISTS price_changes ON products CASCADE;

DROP FUNCTION IF EXISTS log_price_changes();
