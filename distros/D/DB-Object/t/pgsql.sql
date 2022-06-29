-- 01 Creating customers table
CREATE TABLE customers (
     id				SERIAL
    ,first_name		VARCHAR(255)
    ,last_name		VARCHAR(255)
    ,email			VARCHAR(255)
    ,created		TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    ,modified		TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    ,active			BOOLEAN
	,CONSTRAINT pk_customers PRIMARY KEY (id)
	,CONSTRAINT idx_customers UNIQUE (email)
);

-- 02 Creating products table
CREATE TABLE products (
     id				SERIAL
    -- uuid v4
    ,sku			CHAR(36)
    ,name			VARCHAR(255)
	,description	TEXT
    ,created		TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    ,modified		TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
	,CONSTRAINT pk_products PRIMARY KEY (id)
	,CONSTRAINT idx_products UNIQUE (sku)
);

-- 03 Creating orders table
CREATE TABLE orders (
     id				SERIAL
    ,cust_id		INTEGER NOT NULL
    ,sku			CHAR(36)
    ,quantity		INTEGER NOT NULL DEFAULT 0
    ,ordered_on		TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    ,ip_addr        INET
	,CONSTRAINT pk_orders PRIMARY KEY (id)
	,CONSTRAINT idx_orders UNIQUE (cust_id,sku)
    ,CONSTRAINT fk_orders_cust_id FOREIGN KEY (cust_id) REFERENCES public.customers(id) ON DELETE CASCADE
    ,CONSTRAINT fk_orders_sku FOREIGN KEY (sku) REFERENCES public.products(sku) ON DELETE RESTRICT
);

-- 04 Adding customers
INSERT INTO customers (first_name,last_name,email,active) VALUES
	('John','Doe','john@example.org','t'),
	('Bob', 'Roger','bob@example.com', 't');

-- 05 Adding products
INSERT INTO products (sku,name, description) VALUES
	('B86F5AD9-BC02-4E8A-9657-E561251DCDEC','Cool Stuff','Some really cool stuff'),
	('52B39CCC-60DF-4268-BC1E-7A03412AB44F','Great value','Limited edition');

-- 06 Adding orders
INSERT INTO orders (cust_id,sku,quantity) VALUES
	((SELECT id FROM customers WHERE email='john@example.org'),'B86F5AD9-BC02-4E8A-9657-E561251DCDEC',2),
	((SELECT id FROM customers WHERE email='bob@example.com'),'52B39CCC-60DF-4268-BC1E-7A03412AB44F',7);
