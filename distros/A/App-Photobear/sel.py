from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

# Set up Chrome options
chrome_options = Options()
chrome_options.add_argument("--headless")  # Run Chrome in headless mode

# Set up Chrome driver service
webdriver_service = Service('path_to_chromedriver')

# Choose the URL you want to load
url = "https://example.com"

# Create a new instance of the Chrome driver
driver = webdriver.Chrome(service=webdriver_service, options=chrome_options)

# Load the URL
driver.get(url)

# Get the rendered HTML after JavaScript execution
rendered_html = driver.page_source

# Print or process the rendered HTML as needed
print(rendered_html)

# Quit the driver
driver.quit()
