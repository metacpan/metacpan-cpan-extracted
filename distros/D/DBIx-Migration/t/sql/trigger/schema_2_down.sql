DROP TABLE IF EXISTS product_price_changes;

DROP TRIGGER IF EXISTS price_change ON products CASCADE;

DROP FUNCTION IF EXISTS log_price_changes();
